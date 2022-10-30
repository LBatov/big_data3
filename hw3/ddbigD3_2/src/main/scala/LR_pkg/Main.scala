package LR_pkg

import breeze.linalg._
import scala.util.control.Breaks._

object Main extends App{
  def readCSV(): Array[Array[Double]] = {
    io.Source.fromFile("Data/data.csv")
      .getLines()
      .map(_.split(",").map(_.trim.toDouble))
      .toArray
  }

  val data = DenseMatrix(readCSV():_*)
  val total_rows = data.rows
  val train_rows = math.ceil(0.9 * total_rows).toInt
  val train_Y = data(0 to train_rows , 4)
  val train_X = data(0 to train_rows  , 0 to 3)
  val data_val_Y = data(train_rows+1 to total_rows-1, 4)
  val data_val_X = data(train_rows+1 to total_rows-1, 0 to 3)
  val lr = 0.01
  val true_coef = DenseVector(0.7,6.0,0.03,11.0,1.0)


  var coef = DenseVector.rand(5)
  var diff_vector = DenseVector.zeros[Double](coef.length)
  var res_Y = new DenseVector[Double](train_Y.length)
  var val_Y = new DenseVector[Double](data_val_Y.length)

  def calc(param_vector:DenseVector[Double], data_matrix:DenseMatrix[Double]): DenseVector[Double] = {
    val res = data_matrix * param_vector(0 to (param_vector.length - 2)) + param_vector(param_vector.length - 1)

    //val res = sum(param_vector(0 to (param_vector.length - 2)) *:* data_vector,(*, ::)) + param_vector(param_vector.length -1)
    res
  }

  def mse_loss(v1:DenseVector[Double], v2:DenseVector[Double]): Double = {
    val subtr = (v1 - v2)
    val res = sum(subtr * subtr) / (subtr.length.toDouble)
    res
  }


  breakable(
    for (iteration <- 1 to 10000) {
    res_Y := calc(coef, train_X)

    for (param <- 0 to 3)
      {
        diff_vector(param) = sum(train_X(::, param) * (train_Y - res_Y)) / train_rows.toDouble * (-2)
      }
    diff_vector(4) = sum((train_Y - res_Y)) / train_rows.toDouble * (-2)
    diff_vector = diff_vector * lr
    coef = coef - diff_vector
    if (iteration % 100 == 0) {
      val mse = mse_loss(res_Y, train_Y)
      val_Y := calc(coef, data_val_X)
      val val_mse = mse_loss(val_Y, data_val_Y)
      println(f"iteration: $iteration%d train_mse_loss: $mse%1.5f val_mse_loss: $val_mse%1.5f")
      if (val_mse < 1e-3) break
    }
  }
  )
  println(f"result: $coef")
  println(f"true values : $true_coef")
}
