def validate_percentage(value):
    if not isinstance(value, (int, float)):
        raise ValueError("Percentage must be a number.")
    if value < 0 or value > 100:
        raise ValueError("Percentage must be between 0 and 100.")

def format_percentage(value):
    validate_percentage(value)
    return f"{value:.2f}%"

def parse_percentage(value):
    try:
        parsed_value = float(value.strip('%'))
        validate_percentage(parsed_value)
        return parsed_value
    except (ValueError, AttributeError):
        return None

def calculate_total_fees(fee_list):
    return sum(fee_list)

def calculate_effective_rate(base_rate, fee_percentage):
    return base_rate * (1 + fee_percentage / 100)