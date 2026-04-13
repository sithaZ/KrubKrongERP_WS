<template>
  <section class="page-shell">
    <div class="page-header">
      <div>
        <h2>Attendance Management</h2>
        <p>Review attendance records and correct mistakes when needed.</p>
      </div>
    </div>

    <div class="erp-card toolbar-card">
      <div class="toolbar-grid">
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
          <label>Status Filter</label>
          <select v-model="statusFilter" class="erp-select">
            <option value="">All Statuses</option>
            <option value="present">Present</option>
            <option value="late">Late</option>
            <option value="absent">Absent</option>
            <option value="half_day">Half Day</option>
          </select>
        </div>

        <div class="form-group">
          <label>Date Filter</label>
          <input v-model="dateFilter" type="date" class="erp-input" />
        </div>

        <div class="form-group">
          <button @click="fetchAttendance" class="erp-btn-secondary">
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
              <th style="width: 110px;">Code</th>
              <th style="width: 120px;">Date</th>
              <th style="width: 165px;">Check In</th>
              <th style="width: 165px;">Check Out</th>
              <th style="width: 90px;">Hours</th>
              <th style="width: 120px;">Status</th>
              <th style="width: 180px;">Note</th>
              <th style="width: 120px; text-align: right;">Actions</th>
            </tr>
          </thead>

          <tbody>
            <tr v-if="isLoading" class="state-row">
              <td colspan="9">Loading attendance...</td>
            </tr>

            <tr v-else-if="filteredAttendance.length === 0" class="state-row">
              <td colspan="9">No attendance records found.</td>
            </tr>

            <tr v-else v-for="record in filteredAttendance" :key="record._id">
              <td>
                <div class="user-cell">
                  <div class="user-avatar">
                    {{ getEmployeeName(record).charAt(0).toUpperCase() }}
                  </div>
                  <span :title="getEmployeeName(record)">
                    {{ getEmployeeName(record) }}
                  </span>
                </div>
              </td>

              <td class="muted">{{ getEmployeeCode(record) }}</td>
              <td>{{ record.workDate }}</td>
              <td :title="formatDateTime(record.checkIn)">{{ formatDateTime(record.checkIn) }}</td>
              <td :title="formatDateTime(record.checkOut)">{{ formatDateTime(record.checkOut) }}</td>
              <td>{{ Number(record.workedHours || 0).toFixed(2) }}</td>

              <td>
                <span class="status-pill" :class="record.status">
                  <span class="dot"></span>
                  {{ formatStatus(record.status) }}
                </span>
              </td>

              <td class="note-cell" :title="record.note || '-'">
                {{ record.note || '-' }}
              </td>

              <td>
                <div class="actions-inline">
                  <button @click="openEditModal(record)" class="erp-btn-soft">
                    Edit
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
            <h3>Edit Attendance</h3>
            <p class="modal-subtitle">
              Correct attendance record if employee forgot to check in or check out.
            </p>
          </div>

          <button @click="closeModal" class="close-btn">✕</button>
        </div>

        <form @submit.prevent="saveAttendance" class="modal-form">
          <div class="form-row">
            <div class="form-group">
              <label>Check In</label>
              <input
                v-model="formData.checkIn"
                type="datetime-local"
                class="erp-input"
              />
            </div>

            <div class="form-group">
              <label>Check Out</label>
              <input
                v-model="formData.checkOut"
                type="datetime-local"
                class="erp-input"
              />
            </div>
          </div>

          <div class="form-row">
            <div class="form-group">
              <label>Status</label>
              <select v-model="formData.status" class="erp-select">
                <option value="present">Present</option>
                <option value="late">Late</option>
                <option value="absent">Absent</option>
                <option value="half_day">Half Day</option>
              </select>
            </div>

            <div class="form-group">
              <label>Worked Hours</label>
              <input
                v-model.number="formData.workedHours"
                type="number"
                min="0"
                step="0.01"
                class="erp-input"
              />
            </div>
          </div>

          <div class="form-group">
            <label>Note</label>
            <textarea
              v-model="formData.note"
              rows="4"
              placeholder="e.g. Corrected by admin"
              class="erp-textarea"
            ></textarea>
          </div>

          <div class="helper-box">
            <strong>Tip:</strong> Use this only when an employee forgot to check in, check out, or entered attendance incorrectly.
          </div>

          <div class="modal-footer">
            <button type="button" @click="closeModal" class="erp-btn-secondary">Cancel</button>
            <button type="submit" class="erp-btn">Save Changes</button>
          </div>
        </form>
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue';


type EmployeeRef = {
  _id?: string;
  fullName?: string;
  employeeCode?: string;
};

type AttendanceRecord = {
  _id: string;
  employeeId: EmployeeRef | string;
  workDate: string;
  checkIn?: string;
  checkOut?: string;
  status: 'present' | 'late' | 'absent' | 'half_day';
  workedHours: number;
  note?: string;
};

const API_BASE = 'http://localhost:3000/api';

const attendance = ref<AttendanceRecord[]>([]);
const isLoading = ref(true);
const showModal = ref(false);
const currentAttendanceId = ref('');

const searchTerm = ref('');
const statusFilter = ref('');
const dateFilter = ref('');

const formData = ref({
  checkIn: '',
  checkOut: '',
  status: 'present' as 'present' | 'late' | 'absent' | 'half_day',
  workedHours: 0,
  note: '',
});

const getHeaders = () => ({
  'Content-Type': 'application/json',
});

const formatDateTime = (value?: string) => {
  if (!value) return '-';
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return '-';
  return date.toLocaleString();
};

const toDateTimeLocal = (value?: string) => {
  if (!value) return '';
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return '';
  const local = new Date(date.getTime() - date.getTimezoneOffset() * 60000);
  return local.toISOString().slice(0, 16);
};

const formatStatus = (status: string) => {
  if (status === 'half_day') return 'Half Day';
  return status.charAt(0).toUpperCase() + status.slice(1);
};

const getEmployeeName = (record: AttendanceRecord) => {
  if (typeof record.employeeId === 'object') {
    return record.employeeId?.fullName || 'Unknown Employee';
  }
  return 'Unknown Employee';
};

const getEmployeeCode = (record: AttendanceRecord) => {
  if (typeof record.employeeId === 'object') {
    return record.employeeId?.employeeCode || '-';
  }
  return '-';
};

const filteredAttendance = computed(() => {
  return attendance.value.filter((record) => {
    const name = getEmployeeName(record).toLowerCase();
    const code = getEmployeeCode(record).toLowerCase();
    const search = searchTerm.value.toLowerCase().trim();

    const matchSearch = !search || name.includes(search) || code.includes(search);
    const matchStatus = !statusFilter.value || record.status === statusFilter.value;
    const matchDate = !dateFilter.value || record.workDate === dateFilter.value;

    return matchSearch && matchStatus && matchDate;
  });
});

const fetchAttendance = async () => {
  isLoading.value = true;

  try {
    const res = await fetch(`${API_BASE}/attendance`, {
      headers: getHeaders(),
    });

    if (!res.ok) {
      const text = await res.text();
      console.error('Failed to fetch attendance:', text);
      alert('Failed to load attendance.');
      attendance.value = [];
      return;
    }

    const data = await res.json();
    attendance.value = Array.isArray(data) ? data : [];
  } catch (error) {
    console.error('Fetch attendance error:', error);
    alert('Could not connect to attendance API.');
    attendance.value = [];
  } finally {
    isLoading.value = false;
  }
};

const openEditModal = (record: AttendanceRecord) => {
  currentAttendanceId.value = record._id;
  formData.value = {
    checkIn: toDateTimeLocal(record.checkIn),
    checkOut: toDateTimeLocal(record.checkOut),
    status: record.status,
    workedHours: record.workedHours || 0,
    note: record.note || '',
  };
  showModal.value = true;
};

const closeModal = () => {
  showModal.value = false;
};

const saveAttendance = async () => {
  const payload = {
    checkIn: formData.value.checkIn
      ? new Date(formData.value.checkIn).toISOString()
      : undefined,
    checkOut: formData.value.checkOut
      ? new Date(formData.value.checkOut).toISOString()
      : undefined,
    status: formData.value.status,
    workedHours: Number(formData.value.workedHours),
    note: formData.value.note,
  };

  try {
    const response = await fetch(`${API_BASE}/attendance/${currentAttendanceId.value}`, {
      method: 'PATCH',
      headers: getHeaders(),
      body: JSON.stringify(payload),
    });

    if (!response.ok) {
      const text = await response.text();
      console.error('Save attendance failed:', text);
      alert('Failed to update attendance.');
      return;
    }

    closeModal();
    await fetchAttendance();
  } catch (error) {
    console.error('Save attendance error:', error);
    alert('Error updating attendance.');
  }
};

onMounted(fetchAttendance);
</script>