def parse_percentage(value):
    try:
        # Remove any percentage sign and convert to float
        return float(value.strip('%')) / 100
    except ValueError:
        return None

def handle_rate_input_change(rate_inputs, col_key, value):
    rate_inputs[col_key] = value
    return rate_inputs

def handle_rate_input_blur(rate_inputs, rate_overrides, col_key, value, original_rate):
    rate_inputs[col_key] = None
    parsed = parse_percentage(value)
    if parsed is not None and abs(parsed - original_rate) > 1e-5:
        rate_overrides[col_key] = parsed
    else:
        rate_overrides.pop(col_key, None)
    return rate_overrides

def reset_rate_override(rate_overrides, col_key):
    rate_overrides.pop(col_key, None)
    return rate_overrides