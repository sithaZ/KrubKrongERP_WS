import axios from 'axios';

async function run() {
  console.log('Sending login request to backend...');
  try {
    const response = await axios.post('http://localhost:3000/api/auth/login', {
      email: 'baimakowner@gmail.com',
      password: 'password', // wait, does baimakowner have "password" or something else? Let's check what response we get.
    });
    console.log('Response status:', response.status);
    console.log('Response body:', JSON.stringify(response.data, null, 2));
  } catch (error: any) {
    if (error.response) {
      console.log('Error status:', error.response.status);
      console.log('Error body:', JSON.stringify(error.response.data, null, 2));
    } else {
      console.error('Error connecting to backend:', error.message);
    }
  }
}

run();
