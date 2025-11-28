#include <iostream>
#include <fstream>
#include <sstream>
#include <vector>
#include <string>
#include <cmath>
#include <algorithm>
#include <memory>
#include <bitset>
#include <sys/stat.h>
#include <sys/types.h>
#include <cerrno>
using namespace std;

// Check whether a filesystem path exists and is a directory.
static bool dir_exists(const string &path) {
    struct stat st;
    return stat(path.c_str(), &st) == 0 && S_ISDIR(st.st_mode);
}

// Create a directory if it does not already exist. Returns true on success.
static bool create_dir_if_missing(const string &path) {
    if (dir_exists(path)) return true;
    int r = mkdir(path.c_str(), 0755);
    return r == 0 || errno == EEXIST;
}

struct dataStream {
    int id;
    int value;
};

// Split the master CSV into one CSV per sensor.
// Each output CSV has a header 'id,value' where 'id' is a sequential index
// starting at 1 (per sensor) and 'value' is the temperature scaled by 100.
// Parameters:
//  - inputCsv: path to master CSV with first column timestamp and subsequent
//    columns one per sensor
//  - fileCount: expected number of sensors (not strictly enforced)
void splitSensors(const string& inputCsv, int fileCount) {
    ifstream in(inputCsv);
    if(!in.is_open()){
        cerr << "Could not open input CSV\n";
        return;
    }

    // Small helper to trim whitespace from CSV header tokens.
    auto trim = [](const string &s)->string{
        size_t a = s.find_first_not_of(" \t\n\r");
        if (a == string::npos) return string();
        size_t b = s.find_last_not_of(" \t\n\r");
        return s.substr(a, b - a + 1);
    };

    string header;
    getline(in, header);
    stringstream hs(header);
    vector<string> cols;
    string col;
    while(getline(hs, col, ',')){
        cols.push_back(trim(col));
    }
    int sensorCount = cols.size() - 1;

    // Ensure the output directory exists. Files will be written to ./output.
    const string outDir = "output";
    if(!create_dir_if_missing(outDir)){
        cerr << "Could not create output directory: " << outDir << "\n";
        return;
    }

    // Prepare 1 file per sensor in output/
    vector<unique_ptr<ofstream>> outs(sensorCount);
    vector<int> counters(sensorCount, 0);
    for(int i = 0; i < sensorCount; i++){
        // Use the header token as filename, after trimming and sanitization.
        string sensorName = cols[i + 1];
        // sanitize sensorName to be a filename: replace spaces and slashes
        replace(sensorName.begin(), sensorName.end(), ' ', '_');
        replace(sensorName.begin(), sensorName.end(), '/', '_');
        string fname = outDir + "/" + sensorName + ".csv";
        outs[i] = make_unique<ofstream>(fname);
        *outs[i] << "id,value\n";
    }

    string line;
    while(getline(in, line)){
        stringstream ss(line);
        string timestamp;
        getline(ss, timestamp, ','); // first column
        for(int i = 0; i < sensorCount; i++){
            string valueStr;
            if(!getline(ss, valueStr, ',')) break;
            // increment per-sensor counter (acts as a simple time ID)
            counters[i]++;
            if(valueStr.empty()) continue;
            // Parse the temperature, scale by 100 and write as integer
            double v = stod(valueStr);
            int tempInt = (int)round(v * 100.0); // scale temps ×100 (IDs incremented)
            *outs[i] << counters[i] << "," << tempInt << "\n";
        }
    }
}

// NOTE: raw .bin writers were removed — we now keep only the text CSV
// representation of binary values (`<sensor>_binary.csv`).

// Create per-sensor CSV files containing the binary (bitstring) representation
// of each integer value found in `outDir/<sensor>.csv`.
// Result files are named `outDir/<sensor>_binary.csv` and have header
// `id,binary_value` where `binary_value` is a 32-bit zero-padded two's
// complement binary string (e.g. 00000000000000000000011001010100).
void writeBinaryCsvPerSensor(const string &masterCsv, const string &outDir = string("output")) {
    ifstream in(masterCsv);
    if(!in.is_open()){
        cerr << "Could not open master CSV to discover sensors: " << masterCsv << "\n";
        return;
    }

    string header;
    getline(in, header);
    in.close();
    stringstream hs(header);
    string token;
    vector<string> cols;
    auto trim = [](const string &s)->string{
        size_t a = s.find_first_not_of(" \t\n\r");
        if (a == string::npos) return string();
        size_t b = s.find_last_not_of(" \t\n\r");
        return s.substr(a, b - a + 1);
    };
    while(getline(hs, token, ',')) cols.push_back(trim(token));
    if(cols.size() <= 1){
        cerr << "Master CSV header does not contain sensor columns\n";
        return;
    }

    for(size_t i = 1; i < cols.size(); ++i){
        string sensorName = cols[i];
        replace(sensorName.begin(), sensorName.end(), ' ', '_');
        replace(sensorName.begin(), sensorName.end(), '/', '_');
        string csvPath = outDir + "/" + sensorName + ".csv";
        ifstream sIn(csvPath);
        if(!sIn.is_open()){
            cerr << "Could not open preprocessed sensor CSV: " << csvPath << "\n";
            continue;
        }

        string outCsv = outDir + "/" + sensorName + "_binary.csv";
        ofstream oOut(outCsv);
        if(!oOut.is_open()){
            cerr << "Could not create binary CSV output: " << outCsv << "\n";
            sIn.close();
            continue;
        }

        // write header
        oOut << "id,binary_value\n";
        string line;
        getline(sIn, line); // skip header
        while(getline(sIn, line)){
            stringstream ss(line);
            string idStr, valStr;
            if(!getline(ss, idStr, ',')) continue;
            if(!getline(ss, valStr, ',')) continue;
            if(valStr.empty()) continue;
            int32_t v = 0;
            try {
                v = static_cast<int32_t>(stoi(trim(valStr)));
            } catch(...) { continue; }

            // Convert to 32-bit two's complement binary string
            std::bitset<32> bits(static_cast<uint32_t>(v));
            oOut << idStr << "," << bits.to_string() << "\n";
        }

        sIn.close();
        oOut.close();
        cout << "Wrote binary-CSV file: " << outCsv << "\n";
    }
}
