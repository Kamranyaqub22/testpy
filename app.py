import os
import ast
import operator as op
import logging
from flask import Flask, jsonify, request, send_from_directory, abort

# Create app with static folder absolute path
BASE_DIR = os.path.dirname(__file__)
STATIC_DIR = os.path.join(BASE_DIR, 'static')
app = Flask(__name__, static_folder=STATIC_DIR, static_url_path='/static')

logging.basicConfig(level=logging.INFO)
app.logger.setLevel(logging.INFO)

# Allowed operators for AST safe evaluation
ALLOWED_OPERATORS = {
    ast.Add: op.add,
    ast.Sub: op.sub,
    ast.Mult: op.mul,
    ast.Div: op.truediv,
    ast.Mod: op.mod,
    ast.Pow: op.pow,
    ast.USub: op.neg,
    ast.UAdd: op.pos,
}

def safe_eval(expr: str):
    """
    Safely evaluate arithmetic expressions using AST.
    Supports numbers, + - * / % **, parentheses, unary +/-.
    """
    node = ast.parse(expr, mode='eval')

    def _eval(n):
        if isinstance(n, ast.Expression):
            return _eval(n.body)
        if isinstance(n, ast.Constant):  # Python 3.8+
            if isinstance(n.value, (int, float)):
                return n.value
            raise ValueError("Invalid constant")
        if isinstance(n, ast.Num):  # older ast
            return n.n
        if isinstance(n, ast.BinOp):
            left = _eval(n.left)
            right = _eval(n.right)
            op_type = type(n.op)
            if op_type in ALLOWED_OPERATORS:
                return ALLOWED_OPERATORS[op_type](left, right)
            raise ValueError("Operator not allowed")
        if isinstance(n, ast.UnaryOp):
            op_type = type(n.op)
            operand = _eval(n.operand)
            if op_type in ALLOWED_OPERATORS:
                return ALLOWED_OPERATORS[op_type](operand)
            raise ValueError("Unary operator not allowed")
        raise ValueError("Expression not allowed")

    return _eval(node)

@app.route('/status', methods=['GET'])
def status():
    return jsonify({"status": "ok", "static_dir": STATIC_DIR})

@app.route('/', methods=['GET'])
def index():
    index_path = os.path.join(STATIC_DIR, 'index.html')
    if not os.path.exists(index_path):
        app.logger.error("index.html not found at %s", index_path)
        abort(404, description="index.html not found")
    if not os.access(index_path, os.R_OK):
        app.logger.error("index.html not readable at %s", index_path)
        abort(403, description="index.html not readable by server")
    return send_from_directory(STATIC_DIR, 'index.html')

@app.route('/api/calc', methods=['POST'])
def calc():
    data = request.get_json(silent=True) or {}
    expr = data.get('expr', '')
    if not isinstance(expr, str) or not expr.strip():
        return jsonify({"error": "No expression provided"}), 400
    try:
        result = safe_eval(expr)
        return jsonify({"result": result})
    except Exception as e:
        app.logger.info("Evaluation error for [%s]: %s", expr, e)
        return jsonify({"error": str(e)}), 400

if __name__ == '__main__':
    port = int(os.environ.get("PORT", 5000))
    app.logger.info("Starting app on 127.0.0.1:%d, static dir=%s", port, STATIC_DIR)
    app.run(host='127.0.0.1', port=port, debug=True)
