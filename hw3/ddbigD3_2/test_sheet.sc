import breeze.linalg._
import breeze.linalg.sum

val x = DenseMatrix((1.0,2.0,3.0,4.0), (3.0,4.0,5.0,6.0), (1.0,1.0,1.0,1.0))
val coef = DenseVector(1.0,1.0,1.0,2.0)
val res = (x * coef)
println(res)

val dm = DenseMatrix((1.0,2.0,3.0),
  (4.0,5.0,6.0))

val res = dm(::, *) + DenseVector(3.0, 4.0)
//assert(res == DenseMatrix((4.0, 5.0, 6.0), (8.0, 9.0, 10.0)))
println(res)