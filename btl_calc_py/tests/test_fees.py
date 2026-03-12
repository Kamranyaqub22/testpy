import unittest
from btl_calc.fees import handle_fee_input_change, handle_fee_input_blur, handle_reset_fee_override

class TestFees(unittest.TestCase):

    def setUp(self):
        self.fee_data = {
            'service_fee': 100,
            'broker_fee': 200,
        }

    def test_handle_fee_input_change(self):
        col_key = 'service_fee'
        val = 150
        updated_fees = handle_fee_input_change(self.fee_data, col_key, val)
        self.assertEqual(updated_fees[col_key], val)

    def test_handle_fee_input_blur_with_change(self):
        col_key = 'broker_fee'
        val = '25%'
        orig_pct_dec = 200
        updated_fees = handle_fee_input_blur(self.fee_data, col_key, val, orig_pct_dec)
        self.assertEqual(updated_fees[col_key], 25)

    def test_handle_fee_input_blur_without_change(self):
        col_key = 'service_fee'
        val = '100%'
        orig_pct_dec = 100
        updated_fees = handle_fee_input_blur(self.fee_data, col_key, val, orig_pct_dec)
        self.assertNotIn(col_key, updated_fees)

    def test_handle_reset_fee_override(self):
        col_key = 'broker_fee'
        updated_fees = handle_reset_fee_override(self.fee_data, col_key)
        self.assertNotIn(col_key, updated_fees)

if __name__ == '__main__':
    unittest.main()