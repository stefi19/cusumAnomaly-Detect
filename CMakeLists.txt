cmake_minimum_required(VERSION 4.0)
project(StreamingData)

set(CMAKE_CXX_STANDARD 14)

add_executable(StreamingData
        CusumAnomalyDetection.cpp
        ProcessFiles.cpp
        main.cpp
)
