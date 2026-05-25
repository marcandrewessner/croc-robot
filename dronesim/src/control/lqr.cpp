#include "control_internal.h"

#include <Eigen/Dense>

// Solves the discrete-time algebraic Riccati equation iteratively.
// P = A'PA - (A'PB)(R + B'PB)^{-1}(B'PA) + Q
// Returns K = (R + B'PB)^{-1} B'PA
Eigen::MatrixXd lqr_dare(
    const Eigen::MatrixXd& A,
    const Eigen::MatrixXd& B,
    const Eigen::MatrixXd& Q,
    const Eigen::MatrixXd& R,
    int max_iter, double tol)
{
    Eigen::MatrixXd P = Q;
    for (int i = 0; i < max_iter; i++) {
        Eigen::MatrixXd BtP   = B.transpose() * P;
        Eigen::MatrixXd S     = R + BtP * B;
        Eigen::MatrixXd P_next =
            A.transpose() * P * A - (A.transpose() * P * B) * S.inverse() * BtP * A + Q;
        if ((P_next - P).norm() < tol) { P = P_next; break; }
        P = P_next;
    }
    return (R + B.transpose() * P * B).inverse() * B.transpose() * P * A;
}
