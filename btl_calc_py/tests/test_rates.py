import pytest
from btl_calc.rates import handle_rate_input_change, handle_rate_input_blur

def test_handle_rate_input_change():
    initial_state = {}
    col_key = 'rate1'
    value = 0.05
    expected_state = {'rate1': 0.05}
    
    new_state = handle_rate_input_change(initial_state, col_key, value)
    
    assert new_state == expected_state

def test_handle_rate_input_blur_with_change():
    initial_state = {'rate1': 0.05}
    col_key = 'rate1'
    value = '0.1'
    original_rate = 0.05
    expected_state = {'rate1': 0.1}
    
    new_state = handle_rate_input_blur(initial_state, col_key, value, original_rate)
    
    assert new_state == expected_state

def test_handle_rate_input_blur_without_change():
    initial_state = {'rate1': 0.05}
    col_key = 'rate1'
    value = '0.05'
    original_rate = 0.05
    expected_state = {}
    
    new_state = handle_rate_input_blur(initial_state, col_key, value, original_rate)
    
    assert new_state == expected_state

def test_handle_rate_input_blur_invalid_percentage():
    initial_state = {'rate1': 0.05}
    col_key = 'rate1'
    value = 'invalid'
    original_rate = 0.05
    expected_state = {}
    
    new_state = handle_rate_input_blur(initial_state, col_key, value, original_rate)
    
    assert new_state == expected_state