class OneRepMax {
  static double calculate(double weight, int reps) {
    if (reps == 0) return 0.0;
    if (reps == 1) return weight;
    
    // Epley Formula
    double result = weight * (1 + (reps / 30));
    
    // Return rounded to 1 decimal place
    return double.parse(result.toStringAsFixed(1));
  }
}