#include <iostream>
// #include "omp.h"

#include <algorithm>
#include <fstream>
#include <iostream>
#include <vector>

#define LAYER_0_NUM 10000
#define LAYER_1_NUM 5000
#define LAYER_2_NUM 1000
#define LAYER_3_NUM 500
#define LAYER_4_NUM 100
#define LAYER_5_NUM 50

// g++ -Ofast build.cc -o build

void load_ivecs_data(const char *filename,
                     std::vector<std::vector<float>> &results, unsigned &num,
                     unsigned &dim) {
    std::ifstream in(filename, std::ios::binary);
    if (!in.is_open()) {
        std::cout << "open file error" << std::endl;
        exit(-1);
    }
    in.read((char *)&dim, 4);

    in.seekg(0, std::ios::end);
    std::ios::pos_type ss = in.tellg();
    size_t fsize = (size_t)ss;
    num = (unsigned)(fsize / (dim + 1) / 4);
    results.resize(num);
    for (unsigned i = 0; i < num; i++)
        results[i].resize(dim);

    in.seekg(0, std::ios::beg);
    for (size_t i = 0; i < num; i++) {
        in.seekg(4, std::ios::cur);
        in.read((char *)results[i].data(), dim * 4);
    }
    in.close();
}

float compute_distance(std::vector<float> &vec1, std::vector<float> &vec2,
                       int dim) {
    float s = 0;
    for (int i = 0; i < dim; i++) {
        float t = vec1[i] - vec2[i];
        s += t * t;
    }
    return s;
}

struct Point {
    int idx; // one neighbor idx
    float dis; // distance of neighbor
    std::vector<float> vec; // neighbor's raw data
};

Point find_max_neighbor(std::vector<Point> neighbor_list) {
    Point max_point = neighbor_list[0];
    for (size_t i = 0; i < neighbor_list.size(); i++) {
        if (max_point.dis < neighbor_list[i].dis){
            max_point = neighbor_list[i];
        }
    }
    return max_point;
}

Point find_min_neighbor(std::vector<Point> neighbor_list) {
    Point min_point = neighbor_list[0];
    for (size_t i = 0; i < neighbor_list.size(); i++) {
        if (min_point.dis > neighbor_list[i].dis){
            min_point = neighbor_list[i];
        }
    }
    return min_point;
}

std::vector<Point> find_neighbors(
    std::vector<std::vector<float>> &dataSet,
    std::vector<float> &vec,
    size_t num,
    int dim,
    int target_index  // 新增参数：目标点的索引
) {
    std::vector<Point> all_points;
    for (int i = 0; i < num; ++i) {
        if (i == target_index) continue; // 排除自身
        float dis = compute_distance(dataSet[i], vec, dim);
        Point tmp = {i, dis, dataSet[i]};
        all_points.push_back(tmp);
    }
    // 按距离从小到大排序
    std::sort(all_points.begin(), all_points.end(), 
             [](const Point& a, const Point& b) { return a.dis < b.dis; });
    // 截取前32个
    if (all_points.size() > 32) {
        all_points.resize(32);
    }
    return all_points;
}

void save_binary(const char *filename, 
    const std::vector<std::vector<float>> &,
    const std::vector<std::vector<Point>> &,
    unsigned , 
    unsigned );
int main(int argc, char **argv) {
    std::vector<std::vector<float>> true_load;
    unsigned dim, num;
    load_ivecs_data(argv[1], true_load, num, dim);

    // std::cout << "result_num：" << num << std::endl
    //           << "result dimension：" << dim << std::endl;
    // for (size_t i = 0; i < num; i++) {
    //     for (size_t j = 0; j < dim; j++) {
    //         std::cout << true_load[i][j] << " ";
    //     }
    //     std::cout << std::endl;
    // }
    std::cout << "result_num：" << num /* << true_load.size() */ << std::endl
              << "result dimension：" << dim << std::endl;

    std::cout << "distance " << 1 << " " << 3 << " "
              << compute_distance(true_load[1], true_load[3], dim) << std::endl;

    std::vector<std::vector<Point>> neighbor_lists;
    // #pragma omp parallel // for num_threads(12)
    for (int i=0; i<10000; i++) {
        std::vector<Point> one_neighbor_list = find_neighbors(true_load, true_load[i], num, dim, i);
        neighbor_lists.push_back(one_neighbor_list);
    }
    
    int target = 1;

    // std::vector<Point> neighbors0 = find_neighbors(true_load, true_load[target], num, dim, target);
    // neighbor_lists.push_back(neighbors0);

    std::cout << target << "point's neighbor's idxs: ";
    for (size_t i = 0; i < neighbor_lists[target].size(); i++) {
        std::cout << "(" << neighbor_lists[target][i].idx << ", " << neighbor_lists[target][i].dis << ")" << " ";
    }
    std::cout << std::endl;
    save_binary("output.bin", true_load, neighbor_lists, num, dim);

    return 0;
}

void save_binary(const char *filename, 
    const std::vector<std::vector<float>> &data,
    const std::vector<std::vector<Point>> &neighborList,
    unsigned num, 
    unsigned dim) {
    std::ofstream out(filename, std::ios::binary);
    if (!out.is_open()) {
    std::cerr << "Failed to open file for writing" << std::endl;
    return;
    }

    size_t addr=0;
    // Store neighbor list
    std::cout << "Starting saving neighbor list at addr 0x" << std::hex << addr << std::dec << std::endl;
    for (size_t j=0; j<num; j++) {
        for (size_t k=0; k<32; k++) {
            out.write((char *)(&neighborList[j][k].idx), 4);
            addr += 4;
        }
    }

    // Strore RAW data
    std::cout << "Starting saving RAW data at addr 0x" << std::hex << addr << std::dec << std::endl;
    size_t i;
    for (i=0; i<num; i++) {
        // out.write((char *)(&dim), 4);
        out.write((char *)(data[i].data()), dim * 4);
        addr += dim * 4;
        /* 👆一样的👇 */
        // out.write(reinterpret_cast<const char*>(&dim), 4);
        // out.write(reinterpret_cast<const char*>(data[i].data()), 
    }
    std::cout << "save " << i << " points; addr tail = " << std::hex << addr << std::dec << std::endl;
    out.close();
}
