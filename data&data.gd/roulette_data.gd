extends Node

const wheel_numbers = [0, 32, 15, 19, 4, 21, 2, 25, 17, 34, 6, 27, 13, 36, 11, 30, 8, 23, 10, 5, 24, 16, 33, 1, 20, 14, 31, 9, 22, 18, 29, 7, 28, 12, 35, 3, 26]
const blacks = [2, 4, 6, 8, 10, 11, 13, 15, 17, 20, 22, 24, 26, 28, 29, 31, 33, 35]
const reds = [1, 3, 5, 7, 9, 12, 14, 16, 18, 19, 21, 23, 25, 27, 30, 32, 34, 36]
const evens = [2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 32, 34, 36]
const odds = [1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25, 27, 29, 31, 33, 35]
const lows = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18]   
const highs = [19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36] 
const first_dozen = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
const second_dozen = [13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24]
const third_dozen = [25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36]
const first_column = [1, 4, 7, 10, 13, 16, 19, 22, 25, 28, 31, 34]
const second_column = [2, 5, 8, 11, 14, 17, 20, 23, 26, 29, 32, 35]
const third_column = [3, 6, 9, 12, 15, 18, 21, 24, 27, 30, 33, 36]
const square_numbers = [0, 1, 4, 9, 16, 25, 36]
const bet_amount: int = 67
# You can also add helpful universal functions here
func is_red(number: int) -> bool:
	return number in reds
