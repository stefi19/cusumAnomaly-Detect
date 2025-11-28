// CUSUM anomaly detection implementation (soft version)
// This file exposes `cusumAlg` which accepts a series of `dataStream`
// samples and returns a vector containing the samples where the CUSUM
// detector raised an alarm.

#include <iostream>
#include <vector>
using namespace std;

// Simple struct representing an (id, value) sample.
struct dataStream
{
    int id;
    int value;
};

// cusumAlg - run a two-sided soft CUSUM on integer samples.
// Inputs:
//   x         - vector of dataStream samples, ordered in time
//   threshold - alarm threshold (integer scale)
//   drift     - drift (also integer scale)
// Output:
//   vector<dataStream> containing samples at which an alarm was raised
// NOTE: Algorithm logic is intentionally left unchanged (user requested no edits).
vector<dataStream> cusumAlg (vector<dataStream> x, int threshold, int drift)
{
    int n = x.size();
    vector <dataStream> result;
    vector <int> s;
    vector <int> gplus;
    vector <int> gminus;

    // initialize running arrays
    s.push_back(0);
    gplus.push_back(0);
    gminus.push_back(0);

    // iterate samples (start at 1 because we compute differences)
    for(int t = 1; t<n; t++)
    {
        int v = x[t].value;
        s.push_back(v - x[t-1].value);

        // update one-sided CUSUM statistics and clamp at zero
        gplus.push_back(max(gplus[t-1] + s[t] - drift, 0));
        gminus.push_back(max(gminus[t-1] - s[t] - drift, 0));

        // raise alarm if either one-sided statistic exceeds threshold
        if(gplus[t] > threshold || gminus[t] > threshold)
        {
            result.push_back(x[t]);
            // reset after alarm (soft reset)
            gplus[t] = 0;
            gminus[t] = 0;
        }
    }
    return result;
}

// End of CUSUM implementation
