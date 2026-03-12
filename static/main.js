document.addEventListener('DOMContentLoaded', () => {
  const exprDisplay = document.getElementById('exprDisplay');
  const resultDisplay = document.getElementById('resultDisplay');
  const historyList = document.getElementById('historyList');
  const clearHistoryBtn = document.getElementById('clearHistory');

  let expr = '';
  let history = JSON.parse(localStorage.getItem('calc_history') || '[]');

  function renderDisplays() {
    exprDisplay.textContent = expr || '0';
  }
  function saveHistory() {
    localStorage.setItem('calc_history', JSON.stringify(history.slice(0, 100)));
  }
  function pushHistory(item) {
    history.unshift(item);
    if (history.length > 100) history.pop();
    saveHistory();
    renderHistory();
  }
  function renderHistory() {
    historyList.innerHTML = '';
    history.forEach(h => {
      const li = document.createElement('li');
      li.textContent = `${h.expr} = ${h.result}`;
      li.addEventListener('click', () => {
        expr = h.expr;
        resultDisplay.textContent = h.result;
        renderDisplays();
      });
      historyList.appendChild(li);
    });
  }

  function sanitizeForClientEval(s) {
    // Allow digits, whitespace and arithmetic symbols only
    return /^[0-9+\-*/().\s%]*$/.test(s);
  }

  async function evaluateExpr() {
    if (!expr.trim()) return;
    resultDisplay.textContent = 'Calculating...';

    // Try backend first
    try {
      const res = await fetch('/api/calc', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({expr})
      });
      const data = await res.json();
      if (res.ok && data.result !== undefined) {
        resultDisplay.textContent = String(data.result);
        pushHistory({expr, result: data.result});
        return;
      }
      // backend returned error -> fall through to client eval attempt
      console.warn('Backend eval error:', data);
    } catch (err) {
      console.warn('Backend unavailable, falling back to client eval', err);
    }

    // Fallback: safe client-side eval (only if sanitized)
    if (!sanitizeForClientEval(expr)) {
      resultDisplay.textContent = 'Invalid expression';
      return;
    }
    try {
      // eslint-disable-next-line no-new-func
      const fn = new Function('return (' + expr + ')');
      const val = fn();
      if (typeof val === 'number' && isFinite(val)) {
        resultDisplay.textContent = String(val);
        pushHistory({expr, result: val});
      } else {
        resultDisplay.textContent = 'Invalid result';
      }
    } catch (e) {
      resultDisplay.textContent = 'Error';
    }
  }

  // Button handlers
  document.querySelectorAll('.keypad .btn').forEach(btn => {
    btn.addEventListener('click', () => {
      const v = btn.dataset.value;
      const action = btn.dataset.action;
      if (action === 'clear') {
        expr = '';
        resultDisplay.textContent = '';
        renderDisplays();
        return;
      }
      if (action === 'back') {
        expr = expr.slice(0, -1);
        renderDisplays();
        return;
      }
      if (action === 'equals') {
        evaluateExpr();
        return;
      }
      if (v !== undefined) {
        let toAdd = v;
        if (v === '×') toAdd = '*';
        if (v === '÷') toAdd = '/';
        expr += toAdd;
        renderDisplays();
      }
    });
  });

  // Keyboard support
  window.addEventListener('keydown', (e) => {
    const allowed = '0123456789+-*/().%';
    if (e.key === 'Enter') {
      e.preventDefault();
      evaluateExpr();
      return;
    }
    if (e.key === 'Backspace') {
      expr = expr.slice(0, -1);
      renderDisplays();
      return;
    }
    if (e.key === 'Escape') {
      expr = '';
      resultDisplay.textContent = '';
      renderDisplays();
      return;
    }
    if (allowed.includes(e.key)) {
      expr += e.key;
      renderDisplays();
    }
  });

  clearHistoryBtn.addEventListener('click', () => {
    history = [];
    saveHistory();
    renderHistory();
  });

  // initial render
  renderDisplays();
  renderHistory();
});
