import { show as showLoadingScreen } from '../loading-screen.js';

window.addEventListener('load', (_event) => {
  addFormSubmissionEventHandler();
});

function addFormSubmissionEventHandler() {
  document.addEventListener('submit', handleFormSubmissionEvent);
}

function handleFormSubmissionEvent(_event: Event) {
  showLoadingScreen();
}
