import { show as showLoadingScreen } from '../loading-screen.js';

window.addEventListener('load', () => {
  searchPollID();
  createNewPoll();
  handleHover();
  handleScreenWidthChange();
});

function handleScreenWidthChange() {
  swapToLightPlusOnMobile();
  window.addEventListener('resize', swapToLightPlusOnMobile);
}

function swapToLightPlusOnMobile() {
  let img = document.getElementById('create-new-plus-img') as HTMLImageElement;
  let isDesktop = window.innerWidth >= 768;
  if (isDesktop && img.src != '/images/outfit/plus-sign.png') {
    //img.src = '/images/outfit/plus-sign.png'; //commented out for dark mode
  } else if (img.src != '/images/outfit/plus-sign-light.png') {
    img.src = '/images/outfit/plus-sign-light.png';
  }
}

function handleHover() {
  //commented out for dark mode
  // let img = document.getElementById('create-new-plus-img') as HTMLImageElement;
  // let isDesktop = window.innerWidth >= 768;
  // $('#create-new-poll-div').hover(
  //   function () {
  //     img.src = '/images/outfit/plus-sign-light.png';
  //   },
  //   function () {
  //     if (isDesktop) {
  //       img.src = '/images/outfit/plus-sign.png';
  //     }
  //   },
  // );
}

function createNewPoll() {
  $('#create-new-poll-div').on('click', () => {
    location.href = document.URL + '/create';
  });
}

function searchPollID() {
  let btn = document.getElementById('poll-search-button') as HTMLElement;
  let form = document.getElementById('pollSearchForm') as HTMLFormElement;
  form.addEventListener('submit', function (event) {
    swapURL(event);
  });
  btn.addEventListener('click', function (event) {
    swapURL(event);
  });
}

function swapURL(event: Event) {
  showLoadingScreen();
  event.preventDefault();
  let pollID = (document.getElementById('poll-search-input') as HTMLInputElement).value;
  location.href = document.URL + '/' + pollID;
}
