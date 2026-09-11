import './style.css';

document.querySelector('#app').innerHTML = `
  <div>
    <h1>Hello Vite!</h1>
    <div class="card">
      <button id="counter" type="button">Count is 0</button>
    </div>
    <p class="read-the-docs">Click the button to load a lazy chunk.</p>
  </div>
`;

let count = 0;
const button = document.querySelector('#counter');

button.addEventListener('click', async () => {
    count++;
    button.textContent = `Count is ${count}`;

    const {
        loadExtra
    } = await import('./extra.js');
    loadExtra();
}, {
    once: true
});