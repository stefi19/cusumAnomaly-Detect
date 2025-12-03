#include <iostream>
#include <fstream>
#include <sstream>
#include <vector>
#include <string>
#include <algorithm>
#include <sys/stat.h>
#include <sys/types.h>
#include <cerrno>
using namespace std;

static bool file_exists(const string &path) {
    ifstream f(path);
    return f.good();
}

static bool dir_exists(const string &path) {
    struct stat st;
    return stat(path.c_str(), &st) == 0 && S_ISDIR(st.st_mode);
}

static bool create_dir_if_missing(const string &path) {
    if (dir_exists(path)) return true;
    int r = mkdir(path.c_str(), 0755);
    return r == 0 || errno == EEXIST;
}

struct dataStream {
    int id;
    int value;
};

void splitSensors(const string& inputCsv, int fileCount);
void writeBinaryCsvPerSensor(const string &masterCsv, const string &outDir = string("output"));
vector<dataStream> cusumAlg(vector<dataStream> x, int threshold, int drift);

static string trim(const string &s) {
    size_t a = s.find_first_not_of(" \t\n\r");
    if (a == string::npos) return "";
    size_t b = s.find_last_not_of(" \t\n\r");
    return s.substr(a, b - a + 1);
}

vector<dataStream> loadSeries(const string &path) {
    ifstream in(path);
    vector<dataStream> data;
    if (!in.is_open()) return data;
    string line, header;
    getline(in, header); // discard header

    while(getline(in, line)) {
        stringstream ss(line);
        string idStr, valStr;
        getline(ss, idStr, ',');
        getline(ss, valStr, ',');
        if(idStr.empty() || valStr.empty()) continue;
        data.push_back({stoi(trim(idStr)), stoi(trim(valStr))});
    }
    return data;
}

int main(int argc, char** argv) {
    // Absolute path to the master CSV containing all sensor columns.
    string bigCsv = "/Users/stefi/Desktop/Uni/SCS/StreamingData/04-12-22_temperature_measurements.csv";

    if(!ifstream(bigCsv).good()){
        cerr << "Big CSV not found: " << bigCsv << "\n";
        return 1;
    }

    // Read the header line to discover sensor column names
    ifstream headerIn(bigCsv);
    string headerCol;
    getline(headerIn, headerCol);
    headerIn.close();
    stringstream hs(headerCol);
    string ts;
    vector<string> sensorNames;

    getline(hs, ts, ','); // first = timestamp (ignored)
    while(getline(hs, ts, ',')){
        sensorNames.push_back(trim(ts)); // trim whitespace from header tokens
    }

    if(sensorNames.size() != 6){
        cerr << "Expected 6 sensors in header, found " << sensorNames.size() << "\n";
        return 1;
    }

    // Print the detected sensor names
    cout << "Sensors detected from big CSV: ";
    for(const auto& s : sensorNames) cout << s << " ";
    cout << "\n";

    // Phase 1: create per-sensor CSV files in `output/<sensor>.csv` with columns id,value
    splitSensors(bigCsv, 6);

    // Produce a CSV containing binary strings for each sensor value
    // (we no longer write raw .bin files)
    writeBinaryCsvPerSensor(bigCsv, string("output"));
    // Phase 2: run CUSUM on each generated file
    // Default CUSUM parameters (scaled integers: 2.0°C -> 200, 0.5°C -> 50)
    int THRESHOLD = 200;
    int DRIFT = 50;

    // Simple command-line parsing to override threshold and drift if provided.
    // Usage examples:
    //   ./streaming --threshold 150 --drift 40
    for(int i=1;i<argc;i++){
        string a = argv[i];
        if((a == "-t" || a == "--threshold") && i+1 < argc){ THRESHOLD = stoi(argv[++i]); continue; }
        if((a == "-d" || a == "--drift") && i+1 < argc){ DRIFT = stoi(argv[++i]); continue; }
        if(a == "-h" || a == "--help"){ cout << "Usage: " << argv[0] << " [--threshold N] [--drift N]\n"; return 0; }
    }

    // Keep a summary of anomaly counts per sensor
    vector<pair<string,int>> anomalySummary;
    for(const auto& sname : sensorNames){
        // sanitize sensor name like splitSensors
        string sensorFileName = sname;
        replace(sensorFileName.begin(), sensorFileName.end(), ' ', '_');
        replace(sensorFileName.begin(), sensorFileName.end(), '/', '_');
        string inPath = string("output/") + sensorFileName + ".csv";
        if(!file_exists(inPath)){
            cerr << "Sensor file missing: " << inPath << "\n";
            continue;
        }
        vector<dataStream> series = loadSeries(inPath);
        vector<dataStream> anomalies = cusumAlg(series, THRESHOLD, DRIFT);

        string rezPath = string("output/") + sensorFileName + "_rez_soft.csv";
        ofstream out(rezPath);
        out << "id,value\n";
        for(const auto& a : anomalies){
            out << a.id << "," << a.value << "\n";
        }
        cout << anomalies.size() << " anomalies for " << sname << " saved -> " << rezPath << "\n";
        anomalySummary.push_back({sname, (int)anomalies.size()});
    }

    // Print concise summary table
    cout << "\nAnomaly summary (sensor : count)\n";
    for(const auto &p : anomalySummary) cout << p.first << " : " << p.second << "\n";

    // Try to call the plotting script to produce PNGs (requires matplotlib).
    // Prefer the project's .venv_plot python if available so runs from build dirs
    // will use the intended virtual environment.
    vector<string> candidates = {
        string("plot_anomalies.py"),
        string("../plot_anomalies.py"),
        string("../StreamingData/plot_anomalies.py"),
        string("../../StreamingData/plot_anomalies.py"),
        string("../..//plot_anomalies.py")
    };
    string scriptPath;
    for(const auto &c : candidates){
        if(file_exists(c)){
            scriptPath = c;
            break;
        }
    }
    if(!scriptPath.empty()){
        // prefer venv python if available (relative paths commonly used by the project)
        vector<string> pythonCandidates = {
            string("../.venv_plot/bin/python3"),
            string("../.venv_plot/bin/python"),
            string("../../StreamingData/.venv_plot/bin/python3"),
            string("/Users/stefi/Desktop/Uni/SCS/StreamingData/.venv_plot/bin/python3")
        };
        string pythonExec = "python3"; // fallback
        for(const auto &p : pythonCandidates){
            if(file_exists(p)){
                pythonExec = p;
                break;
            }
        }

        cout << "Running plotting script: " << scriptPath << " using: " << pythonExec << "\n";
        string cmd = pythonExec + string(" ") + scriptPath;
        int r = system(cmd.c_str());
        if(r != 0) cout << "Plotting script returned non-zero exit code: " << r << "\n";
    } else {
        cout << "plot_anomalies.py not found in expected locations; skipping plotting.\n";
    }

    cout << "Output CSVs in ./output\n";
    return 0;
}
