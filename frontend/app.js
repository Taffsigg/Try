const state = {
  token: localStorage.getItem('token'),
  user: JSON.parse(localStorage.getItem('user') || 'null'),
  txPage: 1,
  txFilters: {}
};

const loginView = document.getElementById('loginView');
const appView = document.getElementById('appView');
const userInfo = document.getElementById('userInfo');

const sections = {
  dashboard: document.getElementById('dashboard'),
  clients: document.getElementById('clients'),
  transactions: document.getElementById('transactions'),
  reports: document.getElementById('reports')
};

function can(...roles) {
  return state.user && roles.includes(state.user.role);
}

async function api(path, options = {}) {
  const headers = { 'Content-Type': 'application/json', ...(options.headers || {}) };
  if (state.token) headers.Authorization = `Bearer ${state.token}`;
  const response = await fetch(`/api${path}`, { ...options, headers });
  if (!response.ok) {
    const error = await response.json().catch(() => ({ message: 'Request failed' }));
    throw new Error(error.message || 'Request failed');
  }
  return response;
}

function showSection(name) {
  Object.entries(sections).forEach(([key, el]) => el.classList.toggle('hidden', key !== name));
}

function transactionTable(rows) {
  return `<table><thead><tr><th>ID</th><th>Client</th><th>Asset</th><th>Amount</th><th>USD</th><th>Type</th><th>Status</th><th>Date</th></tr></thead>
  <tbody>${rows
    .map(
      (r) => `<tr><td>${r.id}</td><td>${r.client?.name || '-'}</td><td>${r.asset}</td><td>${r.amount}</td><td>${r.usdEquivalent}</td><td>${r.type}</td><td>${r.status}</td><td>${new Date(r.createdAt).toLocaleString()}</td></tr>`
    )
    .join('')}</tbody></table>`;
}

async function renderDashboard() {
  const data = await (await api('/dashboard')).json();
  sections.dashboard.innerHTML = `
    <h2>Dashboard</h2>
    <div class="cards">
      <div class="card"><h4>Total Transactions</h4><p>${data.totalTransactions}</p></div>
      <div class="card"><h4>Total Client Balances (USD)</h4><p>$${data.totalClientBalances.toFixed(2)}</p></div>
      <div class="card"><h4>Total Revenue (Fees)</h4><p>$${data.totalRevenue.toFixed(2)}</p></div>
    </div>
    <h3>Recent Transactions</h3>
    ${transactionTable(data.recentTransactions)}
  `;
}

async function renderClients() {
  const clients = await (await api('/clients')).json();
  const canEdit = can('admin', 'finance');
  const canDelete = can('admin');

  sections.clients.innerHTML = `
    <h2>Clients</h2>
    ${
      canEdit
        ? `<form id="clientForm" class="card">
            <h3>Add Client</h3>
            <input name="name" placeholder="Name" required />
            <input name="email" placeholder="Email" />
            <textarea name="companyInfo" placeholder="Company info"></textarea>
            <textarea name="wallets" placeholder='Wallets JSON: [{"label":"Main","address":"0x..."}]'></textarea>
            <button type="submit">Save Client</button>
          </form>`
        : ''
    }
    <table><thead><tr><th>Name</th><th>Email</th><th>Company</th><th>Wallets</th><th>Actions</th></tr></thead><tbody>
      ${clients
        .map(
          (c) => `<tr>
          <td>${c.name}</td>
          <td>${c.email || '-'}</td>
          <td>${c.companyInfo || '-'}</td>
          <td>${(c.walletAddresses || []).map((w) => `${w.label || 'Wallet'}: ${w.address}`).join('<br/>') || '-'}</td>
          <td>
            <button data-view-client="${c.id}">View</button>
            ${canDelete ? `<button data-delete-client="${c.id}">Delete</button>` : ''}
          </td>
        </tr>`
        )
        .join('')}
    </tbody></table>
    <div id="clientProfile"></div>
  `;

  if (canEdit) {
    document.getElementById('clientForm').addEventListener('submit', async (e) => {
      e.preventDefault();
      const form = new FormData(e.target);
      let walletAddresses = [];
      try {
        walletAddresses = JSON.parse(form.get('wallets') || '[]');
      } catch {
        alert('Wallet JSON is invalid.');
        return;
      }
      const payload = {
        name: form.get('name'),
        email: form.get('email'),
        companyInfo: form.get('companyInfo'),
        walletAddresses
      };
      await api('/clients', { method: 'POST', body: JSON.stringify(payload) });
      renderClients();
    });
  }

  document.querySelectorAll('[data-delete-client]').forEach((btn) => {
    btn.addEventListener('click', async () => {
      if (!confirm('Delete this client?')) return;
      await api(`/clients/${btn.dataset.deleteClient}`, { method: 'DELETE' });
      renderClients();
    });
  });

  document.querySelectorAll('[data-view-client]').forEach((btn) => {
    btn.addEventListener('click', async () => {
      const client = await (await api(`/clients/${btn.dataset.viewClient}`)).json();
      document.getElementById('clientProfile').innerHTML = `
        <div class="card">
          <h3>Client Profile: ${client.name}</h3>
          <p><strong>Email:</strong> ${client.email || '-'}</p>
          <p><strong>Company:</strong> ${client.companyInfo || '-'}</p>
          <h4>Recent Transactions</h4>
          ${transactionTable(client.transactions || [])}
        </div>
      `;
    });
  });
}

async function renderTransactions() {
  const [transactionsPayload, clients] = await Promise.all([
    (await api(`/transactions?${new URLSearchParams({ ...state.txFilters, page: state.txPage, limit: 10 }).toString()}`)).json(),
    (await api('/clients')).json()
  ]);

  const transactions = transactionsPayload.rows;
  const canAdd = can('admin', 'finance', 'operations');

  sections.transactions.innerHTML = `
    <h2>Transactions</h2>
    ${
      canAdd
        ? `<form id="txForm" class="card">
          <h3>Add Transaction</h3>
          <div class="grid-2">
            <select name="clientId" required>
              <option value="">Select Client</option>
              ${clients.map((c) => `<option value="${c.id}">${c.name}</option>`).join('')}
            </select>
            <input name="asset" placeholder="Asset (BTC/USDT)" required />
            <input name="amount" type="number" step="0.00000001" placeholder="Amount" required />
            <input name="usdEquivalent" type="number" step="0.01" placeholder="USD Equivalent" required />
            <select name="type" required>
              <option value="deposit">Deposit</option><option value="withdrawal">Withdrawal</option>
              <option value="trade">Trade</option><option value="fee">Fee</option>
            </select>
            <select name="status" required>
              <option value="pending">Pending</option><option value="completed">Completed</option><option value="failed">Failed</option>
            </select>
          </div>
          <textarea name="notes" placeholder="Notes"></textarea>
          <button type="submit">Save Transaction</button>
        </form>`
        : ''
    }

    <div class="card">
      <h3>Search/Filter</h3>
      <form id="txFilter" class="grid-2">
        <input name="search" placeholder="Search notes/asset/client" value="${state.txFilters.search || ''}" />
        <input name="asset" placeholder="Asset" value="${state.txFilters.asset || ''}" />
        <select name="status"><option value="">Any Status</option><option ${state.txFilters.status === 'pending' ? 'selected' : ''}>pending</option><option ${state.txFilters.status === 'completed' ? 'selected' : ''}>completed</option><option ${state.txFilters.status === 'failed' ? 'selected' : ''}>failed</option></select>
        <select name="type"><option value="">Any Type</option><option>deposit</option><option>withdrawal</option><option>trade</option><option>fee</option></select>
        <input name="startDate" type="date" value="${state.txFilters.startDate || ''}" />
        <input name="endDate" type="date" value="${state.txFilters.endDate || ''}" />
        <button>Apply</button>
      </form>
    </div>

    <div id="txTable">${transactionTable(transactions)}</div>
    <div class="card" style="margin-top:12px;">
      <button id="prevPage" ${transactionsPayload.page <= 1 ? 'disabled' : ''}>Previous</button>
      <button id="nextPage" ${transactionsPayload.page >= transactionsPayload.totalPages ? 'disabled' : ''}>Next</button>
      <p>Page ${transactionsPayload.page} of ${transactionsPayload.totalPages || 1}</p>
    </div>
  `;

  if (canAdd) {
    document.getElementById('txForm').addEventListener('submit', async (e) => {
      e.preventDefault();
      const form = new FormData(e.target);
      await api('/transactions', {
        method: 'POST',
        body: JSON.stringify({
          clientId: Number(form.get('clientId')),
          asset: form.get('asset'),
          amount: Number(form.get('amount')),
          usdEquivalent: Number(form.get('usdEquivalent')),
          type: form.get('type'),
          status: form.get('status'),
          notes: form.get('notes')
        })
      });
      renderTransactions();
      renderDashboard();
    });
  }

  document.getElementById('txFilter').addEventListener('submit', async (e) => {
    e.preventDefault();
    state.txFilters = Object.fromEntries([...new FormData(e.target).entries()].filter(([, value]) => value));
    state.txPage = 1;
    renderTransactions();
  });

  document.getElementById('prevPage').addEventListener('click', () => {
    state.txPage -= 1;
    renderTransactions();
  });
  document.getElementById('nextPage').addEventListener('click', () => {
    state.txPage += 1;
    renderTransactions();
  });
}

function renderReports() {
  const exportEnabled = can('admin', 'finance');
  sections.reports.innerHTML = `
    <h2>Reports & Export</h2>
    <form id="exportForm" class="card">
      <div class="grid-2">
        <input type="date" name="startDate" />
        <input type="date" name="endDate" />
        <input type="text" name="clientId" placeholder="Client ID" />
        <input type="text" name="asset" placeholder="Asset" />
      </div>
      <button ${exportEnabled ? '' : 'disabled'}>Export Transactions (Excel)</button>
      ${exportEnabled ? '' : '<p>You do not have permission to export.</p>'}
    </form>
    <div id="auditLogs" class="card" style="margin-top: 12px;"></div>
  `;

  document.getElementById('exportForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    if (!exportEnabled) return;
    const query = new URLSearchParams(new FormData(e.target)).toString();
    const response = await api(`/reports/export?${query}`, { headers: {} });
    const blob = await response.blob();
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `transactions_export.xlsx`;
    a.click();
    URL.revokeObjectURL(url);
  });

  if (can('admin', 'finance')) {
    api('/audit-logs?limit=30')
      .then((res) => res.json())
      .then((logs) => {
        document.getElementById('auditLogs').innerHTML = `
          <h3>Latest Audit Logs</h3>
          <table><thead><tr><th>Time</th><th>User</th><th>Action</th><th>Entity</th></tr></thead>
          <tbody>
            ${logs
              .map(
                (l) => `<tr><td>${new Date(l.createdAt).toLocaleString()}</td><td>${l.user?.email || l.userId}</td><td>${l.action}</td><td>${l.entity}</td></tr>`
              )
              .join('')}
          </tbody></table>
        `;
      })
      .catch(() => {
        document.getElementById('auditLogs').innerHTML = '<p>Could not load audit logs.</p>';
      });
  }
}

async function bootstrapApp() {
  if (!state.token || !state.user) {
    loginView.classList.remove('hidden');
    appView.classList.add('hidden');
    return;
  }

  loginView.classList.add('hidden');
  appView.classList.remove('hidden');
  userInfo.textContent = `${state.user.name} (${state.user.role})`;

  await Promise.all([renderDashboard(), renderClients(), renderTransactions()]);
  renderReports();
  showSection('dashboard');
}

document.getElementById('loginForm').addEventListener('submit', async (e) => {
  e.preventDefault();
  const email = document.getElementById('email').value;
  const password = document.getElementById('password').value;

  try {
    const res = await api('/auth/login', {
      method: 'POST',
      headers: {},
      body: JSON.stringify({ email, password })
    });
    const data = await res.json();
    state.token = data.token;
    state.user = data.user;
    localStorage.setItem('token', state.token);
    localStorage.setItem('user', JSON.stringify(state.user));
    bootstrapApp();
  } catch (err) {
    alert(err.message);
  }
});

document.getElementById('logoutBtn').addEventListener('click', () => {
  localStorage.removeItem('token');
  localStorage.removeItem('user');
  state.token = null;
  state.user = null;
  bootstrapApp();
});

document.querySelectorAll('.sidebar nav button').forEach((btn) => {
  btn.addEventListener('click', () => {
    showSection(btn.dataset.section);
    if (btn.dataset.section === 'reports') renderReports();
  });
});

bootstrapApp();
