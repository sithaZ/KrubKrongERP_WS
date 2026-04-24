<template>
  <div class="login-page">
    <div class="bg-mesh"></div>

    <div class="split-layout">
      <div class="form-panel">
        <div class="glass-card">
          <div class="card-header">
            
            <h3>Authentication</h3>
            <p>Enter your credentials to access KrubKrong ERP</p>
          </div>

          <form @submit.prevent="handleLogin" class="modern-form">
            <div class="input-wrapper">
              <input type="text" v-model="username" required placeholder=" " />
              <label>Username</label>
              <div class="underline"></div>
            </div>

            <div class="input-wrapper">
              <input type="password" v-model="password" required placeholder=" " />
              <label>Password</label>
              <div class="underline"></div>
            </div>

            <transition name="fade">
              <div v-if="errorMessage" class="error-toast">
                <span>{{ errorMessage }}</span>
              </div>
            </transition>

            <button type="submit" :disabled="isLoading" class="glow-btn">
              <div class="btn-content" v-if="!isLoading">
                <span>SIGN IN TO SYSTEM</span>
                <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="5" y1="12" x2="19" y2="12"></line><polyline points="12 5 19 12 12 19"></polyline></svg>
              </div>
              <span v-else class="loader"></span>
            </button>
          </form>

          <footer class="form-footer">
            <p>គ្រប់គ្រង ERP &copy; 2026 • SECURE INFRASTRUCTURE</p>
          </footer>
        </div>
      </div>

      <div class="branding-panel">
        <div class="image-overlay"></div>
        
        <div class="panel-content">
          <div class="animation-container">
            <span class="animated-label">STATUS: SYSTEM_READY</span>
            <h1 class="typing-text">
              {{ animatedText }}<span class="cursor">_</span>
            </h1>
          </div>
          
          <div class="brand-info">
            <div class="logo-box">K</div>
            <div class="text-box">
              <h2>KRUBKRONG <span class="highlight">ERP</span></h2>
              <p>Cambodia's Leading SME Solution</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { useRouter } from 'vue-router';


const fullText = "គ្រប់គ្រង";
const animatedText = ref("");
let isDeleting = false;
let charIndex = 0;

const typeEffect = () => {
  const currentSpeed = isDeleting ? 80 : 150; 
  if (!isDeleting && charIndex <= fullText.length) {
    animatedText.value = fullText.substring(0, charIndex);
    charIndex++;
    setTimeout(typeEffect, currentSpeed);
  } else if (isDeleting && charIndex >= 0) {
    animatedText.value = fullText.substring(0, charIndex);
    charIndex--;
    setTimeout(typeEffect, currentSpeed);
  } else {
    isDeleting = !isDeleting;
    setTimeout(typeEffect, isDeleting ? 2000 : 500); 
  }
};

onMounted(() => { typeEffect(); });


const username = ref('');
const password = ref('');
const errorMessage = ref('');
const isLoading = ref(false);
const router = useRouter();


const handleLogin = async () => {
  errorMessage.value = '';
  isLoading.value = true;

  try {
    const response = await fetch('http://localhost:3000/api/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ username: username.value, password: password.value }),
    });

    if (response.ok) {
      const data = await response.json();

      if (data.role !== 'ADMIN') {
        errorMessage.value = 'Access denied. web_admin is available for ADMIN users only.';
        localStorage.removeItem('token');
        localStorage.removeItem('role');
        localStorage.removeItem('access_token');
        localStorage.removeItem('user_role');
        localStorage.removeItem('username');
        return;
      }

      localStorage.setItem('token', data.access_token);
      localStorage.setItem('role', data.role);

      // Keep legacy keys temporarily so existing API calls continue to work.
      localStorage.setItem('access_token', data.access_token);
      localStorage.setItem('user_role', data.role);
      localStorage.setItem('username', data.username || username.value);
      router.push('/dashboard');
    } else {
      const errorData = await response.json();
      errorMessage.value = errorData.message || 'Login failed';
    }
  } catch (error) {
    console.error('Login failed:', error);
    errorMessage.value = 'Unable to connect to the server right now.';
  } finally {
    isLoading.value = false;
  }
};
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;600;800&family=Kantumruy+Pro:wght@300;700&display=swap');

.login-page {
  height: 100vh;
  width: 100vw;
  background: #0f172a;
  overflow: hidden;
  font-family: 'Inter', sans-serif;
  display: flex;
  position: relative;
}

.bg-mesh {
  position: absolute;
  top: 0; left: 0; width: 100%; height: 100%;
  background-image: 
    radial-gradient(at 0% 0%, rgba(30, 58, 138, 0.3) 0px, transparent 50%),
    radial-gradient(at 100% 100%, rgba(15, 23, 42, 0.8) 0px, transparent 50%);
  z-index: 1;
}

.split-layout {
  display: flex;
  width: 100%;
  z-index: 2;
}

/* --- Left Form Side --- */
.form-panel {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 2rem;
  background: rgba(15, 23, 42, 0.2);
}

.glass-card {
  width: 100%;
  max-width: 400px;
  padding: 3rem;
  background: rgba(30, 41, 59, 0.5);
  backdrop-filter: blur(20px);
  border-radius: 24px;
  border: 1px solid rgba(255, 255, 255, 0.1);
}

.card-header h3 { color: white; font-size: 1.75rem; margin-bottom: 0.5rem; }
.card-header p { color: #94a3b8; font-size: 0.9rem; margin-bottom: 2.5rem; }

/* --- Right Branding Side (IMAGE BACKGROUND) --- */
.branding-panel {
  flex: 1.4;
  display: flex;
  align-items: center;
  justify-content: center;
  position: relative;
  background-image: url('../../assets/img/LoginBG.png');
  background-size: cover;
  background-position: center;
  border-left: 1px solid rgba(255, 255, 255, 0.1);
}

.image-overlay {
  position: absolute;
  top: 0; left: 0; width: 100%; height: 100%;
  background: linear-gradient(to right, #0f172a 0%, rgba(15, 23, 42, 0.4) 100%);
  z-index: 1;
}

.panel-content {
  position: relative;
  z-index: 2;
  text-align: left;
  padding: 4rem;
}

.typing-text {
  font-family: 'Kantumruy Pro', sans-serif;
  font-size: 5rem;
  color: white;
  margin: 0;
  text-shadow: 0 0 40px rgba(56, 189, 248, 0.6);
}

.animated-label {
  color: #38bdf8;
  font-size: 0.75rem;
  letter-spacing: 0.3em;
}

.logo-box {
  width: 50px; height: 50px;
  background: white; color: #0f172a;
  display: flex; align-items: center; justify-content: center;
  font-size: 1.8rem; font-weight: 800; border-radius: 10px;
}

.brand-info { display: flex; align-items: center; gap: 1.2rem; margin-top: 2rem;}
.brand-info h2 { color: white; margin: 0; font-size: 1.4rem; }
.highlight { color: #38bdf8; }
.brand-info p { color: #cbd5e1; margin: 0; font-size: 0.9rem;}

/* --- Form Elements --- */
.modern-form { display: flex; flex-direction: column; gap: 2.2rem; }
.input-wrapper { position: relative; }
.input-wrapper input {
  width: 100%; padding: 10px 0; font-size: 1rem; color: white;
  background: transparent; border: none;
  border-bottom: 1px solid rgba(255, 255, 255, 0.2); outline: none;
}
.input-wrapper label {
  position: absolute; top: 10px; left: 0; color: #64748b;
  pointer-events: none; transition: 0.3s;
}
.input-wrapper input:focus ~ label,
.input-wrapper input:not(:placeholder-shown) ~ label {
  top: -20px; font-size: 0.8rem; color: #38bdf8;
}
.underline {
  position: absolute; bottom: 0; left: 0; width: 0%; height: 2px;
  background: #38bdf8; transition: 0.4s;
}
.input-wrapper input:focus ~ .underline { width: 100%; }

.glow-btn {
  background: #38bdf8; color: #0f172a; border: none; padding: 1rem;
  border-radius: 12px; font-weight: 800; cursor: pointer; transition: 0.3s;
}
.glow-btn:hover { box-shadow: 0 0 20px rgba(56, 189, 248, 0.5); transform: translateY(-2px); }
.btn-content { display: flex; align-items: center; justify-content: center; gap: 10px; }

.error-toast {
  background: rgba(239, 68, 68, 0.15); border-left: 4px solid #ef4444;
  color: #f87171; padding: 0.75rem; font-size: 0.85rem; border-radius: 4px;
}

.form-footer { margin-top: 3rem; text-align: center; }
.form-footer p { font-size: 0.65rem; color: #475569; letter-spacing: 0.1em; }

@keyframes blink { 50% { opacity: 0; } }
.cursor { animation: blink 0.8s infinite; color: #38bdf8; }

.loader {
  width: 20px; height: 20px; border: 3px solid rgba(15, 23, 42, 0.3);
  border-radius: 50%; border-top-color: #0f172a; animation: spin 1s linear infinite;
}
@keyframes spin { to { transform: rotate(360deg); } }

@media (max-width: 1024px) {
  .branding-panel { display: none; }
}
</style>
