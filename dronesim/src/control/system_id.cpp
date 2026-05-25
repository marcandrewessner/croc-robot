#include "control.h"
#include "control_internal.h"

#include <Eigen/Dense>
#include <iostream>
#include <vector>

using MjRowMat = Eigen::Matrix<mjtNum, Eigen::Dynamic, Eigen::Dynamic, Eigen::RowMajor>;

Eigen::Matrix<mjtNum, kNs,   kNs>   sysid_A;
Eigen::Matrix<mjtNum, kNs,   kNu>   sysid_B;
Eigen::Matrix<mjtNum, kNout, kNs>   sysid_C;
Eigen::Matrix<mjtNum, kNout, kNu>   sysid_D;

/*
* The extracted state looks as follwoing
*
* state x = <vec12x1>
* [x y z
*  roll pitch yaw
*  vx vy vz
*  p q r]
*
* with
* input u = <vec4x1>
* [t1 t2 t3 t4]
*/

int control_system_id(mjModel* m, mjData* d) {
  std::vector<mjtNum> rawA(kNs * kNs), rawB(kNs * kNu);
  std::vector<mjtNum> rawC(kNout * kNs), rawD(kNout * kNu);

  mjd_transitionFD(
    m, d, 1e-6, 1,
    rawA.data(), rawB.data(),
    rawC.data(), rawD.data()
  );

  auto map_mj_mat = [](mjtNum* data, int r, int c) {
    return Eigen::Map<MjRowMat>(data, r, c);
  };

  sysid_A = map_mj_mat(rawA.data(), kNs,   kNs);
  sysid_B = map_mj_mat(rawB.data(), kNs,   kNu);
  sysid_C = map_mj_mat(rawC.data(), kNout, kNs);
  sysid_D = map_mj_mat(rawD.data(), kNout, kNu);

  std::cout << "A (" << sysid_A.rows() << "x" << sysid_A.cols() << "):\n" << sysid_A << "\n";
  std::cout << "B (" << sysid_B.rows() << "x" << sysid_B.cols() << "):\n" << sysid_B << "\n";
  std::cout << "C (" << sysid_C.rows() << "x" << sysid_C.cols() << "):\n" << sysid_C << "\n";
  std::cout << "D (" << sysid_D.rows() << "x" << sysid_D.cols() << "):\n" << sysid_D << "\n";

  return 0;
}
