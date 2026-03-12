import argparse
from btl_calc.calculations import calculate_effective_rate, calculate_total_fees
from btl_calc.fees import manage_fees
from btl_calc.rates import handle_rate_input

def main():
    parser = argparse.ArgumentParser(description="BTL Calculation CLI")
    parser.add_argument('--calculate', choices=['effective_rate', 'total_fees'], help='Type of calculation to perform')
    parser.add_argument('--rate', type=float, help='Input rate for calculations')
    parser.add_argument('--fees', type=float, nargs='+', help='List of fees to manage')
    
    args = parser.parse_args()

    if args.calculate == 'effective_rate' and args.rate is not None:
        effective_rate = calculate_effective_rate(args.rate)
        print(f"Effective Rate: {effective_rate}")
    
    elif args.calculate == 'total_fees' and args.fees:
        total_fees = calculate_total_fees(args.fees)
        print(f"Total Fees: {total_fees}")
    
    elif args.fees:
        manage_fees(args.fees)
        print("Fees managed successfully.")

if __name__ == "__main__":
    main()