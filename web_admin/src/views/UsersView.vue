<template>
  <section class="page-shell">
    <div class="page-header">
      <div>
        <h2>Employee Management</h2>
        <p>Manage employee records for attendance and payroll.</p>
      </div>

      <button @click="openAddModal" class="erp-btn">
        Add Employee
      </button>
    </div>

    <div class="erp-card toolbar-card">
      <div class="toolbar-grid" style="grid-template-columns: minmax(220px, 1fr) 180px 180px 130px;">
        <div class="form-group">
          <label>Search</label>
          <input
            v-model="searchTerm"
            type="text"
            placeholder="Search by employee name or code"
            class="erp-input"
          />
        </div>

        <div class="form-group">
          <label>Status</label>
          <select v-model="statusFilter" class="erp-select">
            <option value="">All</option>
            <option value="active">Active</option>
            <option value="inactive">Inactive</option>
          </select>
        </div>

        <div class="form-group">
          <label>Department</label>
          <select v-model="departmentFilter" class="erp-select">
            <option value="">All Departments</option>
            <option value="Sales">Sales</option>
            <option value="Operations">Operations</option>
            <option value="HR">HR</option>
            <option value="Finance">Finance</option>
            <option value="IT">IT</option>
            <option value="Admin">Admin</option>
            <option value="General">General</option>
          </select>
        </div>

        <div class="form-group">
          <button @click="fetchEmployees" class="erp-btn-secondary">
            Refresh
          </button>
        </div>
      </div>
    </div>

    <div class="erp-card table-card">
      <div class="table-scroll">
        <table class="erp-table">
          <thead>
            <tr>
              <th style="width: 220px;">Employee</th>
              <th style="width: 120px;">Code</th>
              <th style="width: 150px;">Position</th>
              <th style="width: 150px;">Department</th>
              <th style="width: 140px;">Salary</th>
              <th style="width: 120px;">Status</th>
              <th style="width: 180px; text-align: right;">Actions</th>
            </tr>
          </thead>

          <tbody>
            <tr v-if="isLoading" class="state-row">
              <td colspan="7">Loading employees...</td>
            </tr>

            <tr v-else-if="filteredEmployees.length === 0" class="state-row">
              <td colspan="7">No employees found.</td>
            </tr>

            <tr v-else v-for="employee in filteredEmployees" :key="employee._id">
              <td>
                <div class="user-cell">
                  <div class="user-avatar">
                    {{ employee.fullName?.charAt(0)?.toUpperCase() || 'E' }}
                  </div>
                  <span :title="employee.fullName">{{ employee.fullName }}</span>
                </div>
              </td>

              <td class="muted">{{ employee.employeeCode }}</td>
              <td :title="employee.position || 'Staff'">{{ employee.position || 'Staff' }}</td>
              <td :title="employee.department || 'General'">{{ employee.department || 'General' }}</td>
              <td>{{ employee.salaryType }} - ${{ Number(employee.baseSalary || 0).toFixed(2) }}</td>

              <td>
                <span class="status-pill" :class="employee.isActive ? 'active' : 'inactive'">
                  <span class="dot"></span>
                  {{ employee.isActive ? 'Active' : 'Inactive' }}
                </span>
              </td>

              <td>
                <div class="actions-inline">
                  <button @click="openEditModal(employee)" class="erp-btn-soft">
                    Edit
                  </button>
                  <button @click="deactivateEmployee(employee._id)" class="erp-btn-danger">
                    Deactivate
                  </button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <div v-if="showModal" class="modal-overlay">
      <div class="modal-content">
        <div class="modal-header">
          <div>
            <h3>{{ isEditing ? 'Edit Employee' : 'Add New Employee' }}</h3>
            <p class="modal-subtitle">
              {{ isEditing ? 'Update employee information clearly.' : 'Create a new employee record for your HR system.' }}
            </p>
          </div>

          <button @click="closeModal" class="close-btn">✕</button>
        </div>

        <form @submit.prevent="saveEmployee" class="modal-form">
          <div class="form-row">
            <div class="form-group">
              <label>Full Name</label>
              <input
                v-model="formData.fullName"
                type="text"
                required
                placeholder="e.g. Sok Dara"
                class="erp-input"
              />
            </div>

            <div class="form-group">
              <label>Employee Code</label>
              <input
                v-model="formData.employeeCode"
                type="text"
                required
                placeholder="e.g. EMP001"
                class="erp-input"
              />
            </div>
          </div>

          <div class="form-row">
            <div class="form-group">
              <label>Position</label>
              <input
                v-model="formData.position"
                type="text"
                placeholder="e.g. Cashier"
                class="erp-input"
              />
            </div>

            <div class="form-group">
              <label>Department</label>
              <select v-model="formData.department" class="erp-select">
                <option value="">Select department</option>
                <option value="Sales">Sales</option>
                <option value="Operations">Operations</option>
                <option value="HR">HR</option>
                <option value="Finance">Finance</option>
                <option value="IT">IT</option>
                <option value="Admin">Admin</option>
              </select>
            </div>
          </div>

          <div class="form-row">
            <div class="form-group">
              <label>Salary Type</label>
              <select v-model="formData.salaryType" class="erp-select">
                <option value="daily">Daily</option>
                <option value="monthly">Monthly</option>
              </select>
            </div>

            <div class="form-group">
              <label>Base Salary</label>
              <input
                v-model.number="formData.baseSalary"
                type="number"
                min="0"
                required
                placeholder="e.g. 300"
                class="erp-input"
              />
            </div>
          </div>

          <div class="form-row">
            <div class="form-group">
              <label>Phone</label>
              <input
                v-model="formData.phone"
                type="text"
                placeholder="e.g. 095490904"
                class="erp-input"
              />
            </div>

            <div class="form-group">
              <label>Hire Date</label>
              <input
                v-model="formData.hireDate"
                type="date"
                class="erp-input"
              />
            </div>
          </div>

          <div class="form-group">
            <label>Status</label>
            <select v-model="formData.isActive" class="erp-select">
              <option :value="true">Active</option>
              <option :value="false">Inactive</option>
            </select>
          </div>

          <div class="helper-box">
            <strong>Tip:</strong> Keep employee code unique to avoid payroll and attendance mismatch.
          </div>

          <div class="modal-footer">
            <button type="button" @click="closeModal" class="erp-btn-secondary">Cancel</button>
            <button type="submit" class="erp-btn">Save Employee</button>
          </div>
        </form>
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue';


type Employee = {
  _id: string;
  fullName: string;
  employeeCode: string;
  position?: string;
  department?: string;
  salaryType: 'daily' | 'monthly';
  baseSalary: number;
  isActive: boolean;
  phone?: string;
  hireDate?: string;
};

const API_BASE = 'http://localhost:3000/api';

const employees = ref<Employee[]>([]);
const isLoading = ref(true);
const showModal = ref(false);
const isEditing = ref(false);
const currentEmployeeId = ref('');

const searchTerm = ref('');
const statusFilter = ref('');
const departmentFilter = ref('');

const formData = ref({
  fullName: '',
  employeeCode: '',
  position: '',
  department: '',
  salaryType: 'monthly' as 'daily' | 'monthly',
  baseSalary: 0,
  isActive: true,
  phone: '',
  hireDate: '',
});

const getHeaders = () => {
  const token = localStorage.getItem('access_token');
  return {
    'Content-Type': 'application/json',
    Authorization: token ? `Bearer ${token}` : '',
  };
};

const normalizeDate = (value?: string | Date) => {
  if (!value) return '';
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return '';
  return date.toISOString().split('T')[0];
};

const filteredEmployees = computed(() => {
  const search = searchTerm.value.toLowerCase().trim();

  return employees.value.filter((employee) => {
    const fullName = (employee.fullName || '').toLowerCase();
    const employeeCode = (employee.employeeCode || '').toLowerCase();
    const department = employee.department || 'General';

    const matchSearch =
      !search || fullName.includes(search) || employeeCode.includes(search);

    const matchStatus =
      !statusFilter.value ||
      (statusFilter.value === 'active' && employee.isActive) ||
      (statusFilter.value === 'inactive' && !employee.isActive);

    const matchDepartment =
      !departmentFilter.value || department === departmentFilter.value;

    return matchSearch && matchStatus && matchDepartment;
  });
});

const fetchEmployees = async () => {
  isLoading.value = true;

  try {
    const res = await fetch(`${API_BASE}/employees`, {
      headers: getHeaders(),
    });

    if (!res.ok) {
      const text = await res.text();
      console.error('Failed to fetch employees:', text);
      alert('Failed to load employees.');
      employees.value = [];
      return;
    }

    const data = await res.json();
    employees.value = Array.isArray(data) ? data : [];
  } catch (error) {
    console.error('Fetch employees error:', error);
    alert('Could not connect to employee API.');
    employees.value = [];
  } finally {
    isLoading.value = false;
  }
};

const openAddModal = () => {
  isEditing.value = false;
  currentEmployeeId.value = '';
  formData.value = {
    fullName: '',
    employeeCode: '',
    position: '',
    department: '',
    salaryType: 'monthly',
    baseSalary: 0,
    isActive: true,
    phone: '',
    hireDate: '',
  };
  showModal.value = true;
};

const openEditModal = (employee: Employee) => {
  isEditing.value = true;
  currentEmployeeId.value = employee._id;
  formData.value = {
    fullName: employee.fullName || '',
    employeeCode: employee.employeeCode || '',
    position: employee.position || '',
    department: employee.department || '',
    salaryType: employee.salaryType || 'monthly',
    baseSalary: Number(employee.baseSalary || 0),
    isActive: employee.isActive ?? true,
    phone: employee.phone || '',
    hireDate: normalizeDate(employee.hireDate),
  };
  showModal.value = true;
};

const closeModal = () => {
  showModal.value = false;
};

const saveEmployee = async () => {
  const payload = {
    fullName: formData.value.fullName,
    employeeCode: formData.value.employeeCode,
    position: formData.value.position,
    department: formData.value.department,
    salaryType: formData.value.salaryType,
    baseSalary: Number(formData.value.baseSalary),
    isActive: formData.value.isActive,
    phone: formData.value.phone,
    hireDate: formData.value.hireDate || undefined,
  };

  const url = isEditing.value
    ? `${API_BASE}/employees/${currentEmployeeId.value}`
    : `${API_BASE}/employees`;

  const method = isEditing.value ? 'PATCH' : 'POST';

  try {
    const response = await fetch(url, {
      method,
      headers: getHeaders(),
      body: JSON.stringify(payload),
    });

    if (!response.ok) {
      const text = await response.text();
      console.error('Save employee failed:', text);
      alert('Failed to save employee.');
      return;
    }

    closeModal();
    await fetchEmployees();
  } catch (error) {
    console.error('Save employee error:', error);
    alert('Error saving employee.');
  }
};

const deactivateEmployee = async (id: string) => {
  if (!confirm('Deactivate this employee?')) return;

  try {
    const response = await fetch(`${API_BASE}/employees/${id}/deactivate`, {
      method: 'PATCH',
      headers: getHeaders(),
    });

    if (!response.ok) {
      const text = await response.text();
      console.error('Deactivate employee failed:', text);
      alert('Failed to deactivate employee.');
      return;
    }

    await fetchEmployees();
  } catch (error) {
    console.error('Deactivate employee error:', error);
    alert('Error deactivating employee.');
  }
};

onMounted(fetchEmployees);
</script>