// CUSUM anomaly detection implementation (soft version)
// This file exposes `cusumAlg` which accepts a series of `dataStream`
// samples and returns a vector containing the samples where the CUSUM
// detector raised an alarm.

#include <iostream>
#include <vector>
using namespace std;

struct dataStream
{
    int id;
    int value;
};

vector<dataStream> cusumAlg (vector<dataStream> x, int threshold, int drift)
{
    int n = x.size();
    vector <dataStream> result;
    vector <int> s;
    vector <int> gplus;
    vector <int> gminus;
    s.push_back(0);
    gplus.push_back(0);
    gminus.push_back(0);
    for(int t = 1; t<n; t++)
    {
        int v = x[t].value;
        s.push_back(v - x[t-1].value);
        gplus.push_back(max(gplus[t-1] + s[t] - drift, 0));
        gminus.push_back(max(gminus[t-1] - s[t] - drift, 0));
        if(gplus[t] > threshold || gminus[t] > threshold)
        {
            result.push_back(x[t]);
            gplus[t] = 0;
            gminus[t] = 0;
        }
    }
    return result;
}
