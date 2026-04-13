<template>
  <section class="content-area">
    <div class="page-header">
      <div class="header-left">
        <h2>Payroll Management</h2>
        <p>Generate and finalize employee payroll records.</p>
      </div>

      <button @click="openGenerateModal" class="action-btn">
        Generate Payroll
      </button>
    </div>

    <div class="toolbar-card">
      <div class="toolbar-grid">
        <div class="form-group">
          <label>Search</label>
          <input
            v-model="searchTerm"
            type="text"
            placeholder="Search by employee name or code"
            class="chunky-input"
          />
        </div>

        <div class="form-group">
          <label>Status Filter</label>
          <select v-model="statusFilter" class="chunky-input">
            <option value="">All Statuses</option>
            <option value="draft">Draft</option>
            <option value="finalized">Finalized</option>
          </select>
        </div>

        <div class="form-group">
          <label>Month Filter</label>
          <input v-model="monthFilter" type="month" class="chunky-input" />
        </div>

        <div class="form-group actions-slot">
          <button @click="fetchPayrolls" class="action-btn secondary">
            Refresh
          </button>
        </div>
      </div>
    </div>

    <div class="table-card">
      <table class="data-table">
        <thead>
          <tr>
            <th>Employee</th>
            <th>Code</th>
            <th>Month</th>
            <th>Present</th>
            <th>Late</th>
            <th>Absent</th>
            <th>Gross</th>
            <th>Deduction</th>
            <th>Net</th>
            <th>Status</th>
            <th class="text-right">Actions</th>
          </tr>
        </thead>

        <tbody>
          <tr v-if="isLoading">
            <td colspan="11" class="text-center empty-state">Loading payrolls...</td>
          </tr>

          <tr v-else-if="filteredPayrolls.length === 0">
            <td colspan="11" class="text-center empty-state">No payroll records found.</td>
          </tr>

          <tr v-else v-for="payroll in filteredPayrolls" :key="payroll._id">
            <td class="username-cell">
              <div class="user-avatar-small">
                {{ getEmployeeName(payroll).charAt(0).toUpperCase() }}
              </div>
              {{ getEmployeeName(payroll) }}
            </td>

            <td class="text-muted">{{ getEmployeeCode(payroll) }}</td>
            <td>{{ payroll.month }}</td>
            <td>{{ payroll.presentDays }}</td>
            <td>{{ payroll.lateDays }}</td>
            <td>{{ payroll.absentDays }}</td>
            <td>${{ Number(payroll.grossSalary || 0).toFixed(2) }}</td>
            <td>${{ Number(payroll.deduction || 0).toFixed(2) }}</td>
            <td class="net-salary">${{ Number(payroll.netSalary || 0).toFixed(2) }}</td>
            <td>
              <span class="status-badge" :class="payroll.status">
                <span class="status-dot"></span>
                {{ formatStatus(payroll.status) }}
              </span>
            </td>
            <td class="actions-cell">
              <button
                v-if="payroll.status !== 'finalized'"
                @click="finalizePayroll(payroll._id)"
                class="btn-icon finalize"
              >
                Finalize
              </button>
              <span v-else class="done-label">Done</span>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <div v-if="showGenerateModal" class="modal-overlay">
      <div class="modal-content">
        <div class="modal-header">
          <div>
            <h3>Generate Payroll</h3>
            <p class="modal-subtitle">
              Select an employee and month to generate payroll.
            </p>
          </div>

          <button @click="closeGenerateModal" class="close-btn">✕</button>
        </div>

        <form @submit.prevent="generatePayroll" class="modal-form">
          <div class="form-group">
            <label>Employee</label>
            <select v-model="generateForm.employeeId" class="chunky-input" required>
              <option value="">Select employee</option>
              <option v-for="employee in employees" :key="employee._id" :value="employee._id">
                {{ employee.fullName }} ({{ employee.employeeCode }})
              </option>
            </select>
          </div>

          <div class="form-group">
            <label>Month</label>
            <input
              v-model="generateForm.month"
              type="month"
              class="chunky-input"
              required
            />
          </div>

          <div class="helper-box">
            <strong>Tip:</strong> Generate payroll after attendance records are complete for the selected month.
          </div>

          <div class="modal-footer">
            <button type="button" @click="closeGenerateModal" class="btn-cancel">Cancel</button>
            <button type="submit" class="btn-save">Generate</button>
          </div>
        </form>
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue';


type EmployeeRef = {
  _id: string;
  fullName?: string;
  employeeCode?: string;
};

type PayrollRecord = {
  _id: string;
  employeeId: EmployeeRef | string;
  month: string;
  presentDays: number;
  absentDays: number;
  lateDays: number;
  halfDays: number;
  grossSalary: number;
  deduction: number;
  netSalary: number;
  status: 'draft' | 'finalized';
};

type Employee = {
  _id: string;
  fullName: string;
  employeeCode: string;
};

const API_BASE = 'http://localhost:3000/api';

const payrolls = ref<PayrollRecord[]>([]);
const employees = ref<Employee[]>([]);
const isLoading = ref(true);
const showGenerateModal = ref(false);

const searchTerm = ref('');
const statusFilter = ref('');
const monthFilter = ref('');

const generateForm = ref({
  employeeId: '',
  month: '',
});

const getHeaders = () => ({
  'Content-Type': 'application/json',
});

const getEmployeeName = (payroll: PayrollRecord) => {
  if (typeof payroll.employeeId === 'object') {
    return payroll.employeeId?.fullName || 'Unknown Employee';
  }
  return 'Unknown Employee';
};

const getEmployeeCode = (payroll: PayrollRecord) => {
  if (typeof payroll.employeeId === 'object') {
    return payroll.employeeId?.employeeCode || '-';
  }
  return '-';
};

const formatStatus = (status: string) =>
  status.charAt(0).toUpperCase() + status.slice(1);

const filteredPayrolls = computed(() => {
  return payrolls.value.filter((payroll) => {
    const name = getEmployeeName(payroll).toLowerCase();
    const code = getEmployeeCode(payroll).toLowerCase();
    const search = searchTerm.value.toLowerCase().trim();

    const matchSearch = !search || name.includes(search) || code.includes(search);
    const matchStatus = !statusFilter.value || payroll.status === statusFilter.value;
    const matchMonth = !monthFilter.value || payroll.month === monthFilter.value;

    return matchSearch && matchStatus && matchMonth;
  });
});

const fetchPayrolls = async () => {
  isLoading.value = true;

  try {
    const res = await fetch(`${API_BASE}/payroll`, {
      headers: getHeaders(),
    });

    if (!res.ok) {
      const text = await res.text();
      console.error('Failed to fetch payrolls:', text);
      alert('Failed to load payroll records.');
      payrolls.value = [];
      return;
    }

    const data = await res.json();
    payrolls.value = Array.isArray(data) ? data : [];
  } catch (error) {
    console.error('Fetch payrolls error:', error);
    alert('Could not connect to payroll API.');
  } finally {
    isLoading.value = false;
  }
};

const fetchEmployees = async () => {
  try {
    const res = await fetch(`${API_BASE}/employees`, {
      headers: getHeaders(),
    });

    if (!res.ok) {
      const text = await res.text();
      console.error('Failed to fetch employees:', text);
      employees.value = [];
      return;
    }

    const data = await res.json();
    employees.value = Array.isArray(data) ? data : [];
  } catch (error) {
    console.error('Fetch employees error:', error);
  }
};

const openGenerateModal = () => {
  generateForm.value = {
    employeeId: '',
    month: '',
  };
  showGenerateModal.value = true;
};

const closeGenerateModal = () => {
  showGenerateModal.value = false;
};

const generatePayroll = async () => {
  try {
    const response = await fetch(`${API_BASE}/payroll/generate`, {
      method: 'POST',
      headers: getHeaders(),
      body: JSON.stringify(generateForm.value),
    });

    if (!response.ok) {
      const text = await response.text();
      console.error('Generate payroll failed:', text);
      alert('Failed to generate payroll.');
      return;
    }

    closeGenerateModal();
    await fetchPayrolls();
  } catch (error) {
    console.error('Generate payroll error:', error);
    alert('Error generating payroll.');
  }
};

const finalizePayroll = async (id: string) => {
  if (!confirm('Finalize this payroll?')) return;

  try {
    const response = await fetch(`${API_BASE}/payroll/${id}/finalize`, {
      method: 'PATCH',
      headers: getHeaders(),
    });

    if (!response.ok) {
      const text = await response.text();
      console.error('Finalize payroll failed:', text);
      alert('Failed to finalize payroll.');
      return;
    }

    await fetchPayrolls();
  } catch (error) {
    console.error('Finalize payroll error:', error);
    alert('Error finalizing payroll.');
  }
};

onMounted(async () => {
  await Promise.all([fetchPayrolls(), fetchEmployees()]);
});
</script>

<style scoped>
.content-area {
  padding: 3.5rem 3rem;
  max-width: 1500px;
  margin: 0 auto;
  animation: fadeIn 0.3s ease;
}

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(10px); }
  to { opacity: 1; transform: translateY(0); }
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
  margin-bottom: 2rem;
}

.page-header h2 {
  font-size: 2.2rem;
  color: #111827;
  margin: 0 0 0.75rem 0;
  letter-spacing: -0.5px;
}

.page-header p {
  color: #64748b;
  font-size: 1.1rem;
  margin: 0;
}

.toolbar-card,
.table-card {
  background: white;
  border-radius: 24px;
  padding: 1.25rem;
  box-shadow: 0 12px 30px rgba(15, 23, 42, 0.08);
  border: 1px solid #e2e8f0;
}

.toolbar-card {
  margin-bottom: 1.5rem;
}

.toolbar-grid {
  display: grid;
  grid-template-columns: 2fr 1fr 1fr auto;
  gap: 1rem;
  align-items: end;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 0.6rem;
}

label {
  font-weight: 700;
  color: #1e293b;
  font-size: 0.95rem;
}

.chunky-input {
  width: 100%;
  border: 1.5px solid #cbd5e1;
  background: #ffffff;
  border-radius: 14px;
  padding: 0.95rem 1rem;
  font-size: 1rem;
  color: #111827;
  outline: none;
  transition: all 0.2s ease;
  box-sizing: border-box;
}

.chunky-input:focus {
  border-color: #283375;
  box-shadow: 0 0 0 4px rgba(40, 51, 117, 0.12);
}

.action-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 0.75rem;
  background: #283375;
  color: white;
  border: none;
  border-radius: 14px;
  padding: 1rem 1.4rem;
  font-weight: 700;
  cursor: pointer;
}

.action-btn.secondary {
  background: #e5e7eb;
  color: #111827;
}

.data-table {
  width: 100%;
  border-collapse: collapse;
}

.data-table th,
.data-table td {
  padding: 1rem;
  border-bottom: 1px solid #e5e7eb;
  text-align: left;
}

.data-table th {
  color: #475569;
  font-size: 0.95rem;
  font-weight: 800;
}

.text-right { text-align: right; }
.text-center { text-align: center; }
.empty-state { color: #64748b; padding: 2rem; }
.text-muted { color: #64748b; }

.username-cell {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.user-avatar-small {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  background: #283375;
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 700;
}

.net-salary {
  font-weight: 800;
  color: #047857;
}

.status-badge {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.45rem 0.8rem;
  border-radius: 999px;
  font-size: 0.9rem;
  font-weight: 700;
}
.table-card,
.toolbar-card,
.page-header {
  animation: softAppear 0.22s ease;
}

@keyframes softAppear {
  from {
    opacity: 0;
    transform: translateY(6px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.data-table tbody tr {
  transition: background 0.16s ease, transform 0.16s ease;
}

.data-table tbody tr:hover {
  transform: translateY(-1px);
}
.status-badge.draft {
  background: #fff7ed;
  color: #c2410c;
}

.status-badge.finalized {
  background: #ecfdf5;
  color: #047857;
}

.status-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: currentColor;
}

.actions-cell {
  text-align: right;
}

.btn-icon {
  display: inline-flex;
  align-items: center;
  gap: 0.45rem;
  border: none;
  border-radius: 12px;
  padding: 0.75rem 1rem;
  cursor: pointer;
  font-weight: 700;
}

.btn-icon.finalize {
  background: #eff6ff;
  color: #1d4ed8;
}

.done-label {
  color: #047857;
  font-weight: 700;
}

.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(15, 23, 42, 0.45);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 2rem;
  z-index: 999;
}

.modal-content {
  width: 100%;
  max-width: 620px;
  background: white;
  border-radius: 24px;
  overflow: hidden;
  box-shadow: 0 20px 60px rgba(15, 23, 42, 0.2);
  border: 1px solid #e2e8f0;
}

.modal-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  padding: 1.5rem 2rem;
  border-bottom: 1px solid #e2e8f0;
  background: #ffffff;
}

.modal-header h3 {
  margin: 0;
  font-size: 1.3rem;
  color: #0f172a;
}

.modal-subtitle {
  margin: 0.35rem 0 0;
  color: #64748b;
  font-size: 0.95rem;
}

.close-btn {
  background: transparent;
  border: none;
  cursor: pointer;
  color: #64748b;
  padding: 0.25rem;
  font-size: 1.2rem;
}

.modal-form {
  padding: 2rem;
  background: #f8fafc;
}

.helper-box {
  margin-top: 0.5rem;
  padding: 0.95rem 1rem;
  border-radius: 14px;
  background: #eff6ff;
  color: #1e3a8a;
  border: 1px solid #bfdbfe;
  font-size: 0.95rem;
}

.modal-footer {
  display: flex;
  justify-content: flex-end;
  gap: 1rem;
  margin-top: 1.5rem;
  padding-top: 1rem;
  border-top: 1px solid #e2e8f0;
}

.btn-cancel,
.btn-save {
  border: none;
  border-radius: 14px;
  padding: 0.95rem 1.25rem;
  font-weight: 700;
  cursor: pointer;
}

.btn-cancel {
  background: #e5e7eb;
  color: #111827;
}

.btn-save {
  background: #283375;
  color: white;
}

@media (max-width: 900px) {
  .content-area {
    padding: 2rem 1rem;
  }

  .toolbar-grid {
    grid-template-columns: 1fr;
  }
}
</style>