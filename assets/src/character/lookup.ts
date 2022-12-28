import { show as showLoadingScreen } from './../loading-screen.js';

let contextMenuID = '#character-card-context-menu';
let selectedCharacterName: string;
let selectedCard: HTMLElement | undefined;

window.addEventListener('load', (event) => {
  searchCharacter();
  addCharacterCardClick();
  addContextMenuOptionEventHandlers();
  addDocumentClickEvents();
});

function searchCharacter() {
  let btn = document.getElementById('searchButton');
  let form = document.getElementById('characterSearchForm');
  form?.addEventListener('submit', handleCharacterSearchEvent);
  btn?.addEventListener('click', handleCharacterSearchEvent);

  btn?.addEventListener('auxclick', function (event) {
    if (event.button === 1) {
      let characterName = (document.getElementById('character') as HTMLInputElement).value;
      swapURL(event, characterName, true);
    }
  });
}

function handleCharacterSearchEvent(event: Event) {
  let characterName = (document.getElementById('character') as HTMLInputElement).value;
  swapURL(event, characterName, false);
}

function swapURL(event: Event, characterName: string, newTab: boolean) {
  event.preventDefault();
  if (newTab) {
    const tab = window.open('about:blank')!;
    tab.location = document.URL + '/' + characterName;
  } else {
    showLoadingScreen();
    location.href = document.URL + '/' + characterName;
  }
}

function openURL(event: Event, characterName: string) {
  event.preventDefault();
  var width = window.innerWidth;
  var height = window.innerHeight;
  window.open(
    document.URL + '/' + characterName,
    '_blank',
    'location=yes,width=' + width + ', height=' + height + ',scrollbars=yes,status=yes',
  );
}

function characterCardLeftMouseClick(event: MouseEvent) {
  characterCardClickEvent(event, false);
}

function characterCardMiddleMouseClick(event: MouseEvent) {
  if (event.button === 1) {
    event.preventDefault();
    characterCardClickEvent(event, true);
  }
}

function characterCardMiddleMouseClickPreventDefault(event: MouseEvent) {
  if (event.which === 2) {
    event.preventDefault();
  }
}

function characterCardClickEvent(event: MouseEvent, isMiddleClick: boolean) {
  //make sure it's not a removal
  if (isEventTargetADeleteButtonClick(event)) {
    return;
  }
  let card = $(event.target as HTMLElement).closest('.character-status-card')[0] as HTMLElement;
  if (card != undefined && card.id != undefined && (!isMobileScreen() || selectedCard != card)) {
    let characterName = card.id.split('-')[0];
    let newTab = event.ctrlKey || isMiddleClick;
    swapURL(event, characterName, newTab);
  }
}

function isEventTargetADeleteButtonClick(event: Event) {
  let classList = (event.target as HTMLElement).classList;
  return (
    classList.contains('character-status-card-removal-button-mobile') ||
    classList.contains('character-status-card-removal-button') ||
    classList.contains('fa-trash')
  );
}

function characterCardRightMouseClick(event: MouseEvent) {
  //get card selected
  let card = $(event.target as HTMLElement).closest('.character-status-card')[0];
  if (card != undefined && card.id != undefined) {
    //get character name from card and make it "selected"
    selectedCharacterName = card.id.split('-')[0];
    updateMobileSelectionCard();
    selectedCard = card;
    card.classList.add('character-card-selected');
    if (!isMobileScreen()) {
      //initialize special menu location
      let isFireFox = navigator.userAgent.indexOf('Firefox') != -1;
      let yAdj =
        event.clientY + $(contextMenuID).height()! > $(window).height()!
          ? event.clientY - $(contextMenuID).height()! - (isFireFox ? 0 : 5)
          : event.clientY; //adjust height to show all of menu
      let xAdj =
        event.clientX + $(contextMenuID).width()! > $(window).width()!
          ? event.clientX - $(contextMenuID).width()! - (isFireFox ? 0 : 2)
          : event.clientX; //adjust width to show all of menu
      var top = (yAdj / $(window).height()!) * 100 + '%';
      var left = (xAdj / $(window).width()!) * 100 + '%';

      //show special menu at the bottom right of the mouse
      $(contextMenuID)
        .css({
          display: 'block',
          position: 'fixed',
          top: top,
          left: left,
        })
        .addClass('show');

      //if it's a mobile screen, show remove character option
    } else {
      (card.querySelector('.character-status-card-removal-button-mobile-container') as HTMLElement).classList.remove(
        'd-none',
      );
    }
    return false; //blocks default Webbrowser right click menu
  }
}

function addCharacterCardClick() {
  document.querySelectorAll('.character-status-card').forEach((card) => {
    let cardElement = card as HTMLElement;
    //remove and add LEFT mouse click handler
    cardElement.removeEventListener('click', characterCardLeftMouseClick);
    cardElement.addEventListener('click', characterCardLeftMouseClick);

    //remove and add MIDDLE mouse click handler
    cardElement.removeEventListener('auxclick', characterCardMiddleMouseClick);
    cardElement.addEventListener('auxclick', characterCardMiddleMouseClick);
    cardElement.removeEventListener('mousedown', characterCardMiddleMouseClickPreventDefault);
    cardElement.addEventListener('mousedown', characterCardMiddleMouseClickPreventDefault);

    //remove and add RIGHT mouse click handler
    cardElement.removeEventListener('contextmenu', characterCardRightMouseClick);
    cardElement.addEventListener('contextmenu', characterCardRightMouseClick);
  });

  document.querySelectorAll('.status-card-section-header').forEach((header) => {
    header.addEventListener('click', () => {
      let chevron = header.querySelector('.fa-chevron-up') as HTMLElement;
      $(chevron).toggleClass('down');
    });
  });
}

function addDocumentClickEvents() {
  $(document).on('mousedown', function () {
    hideContextMenu();
    document.querySelectorAll('.character-card-selected').forEach((card) => {
      card.classList.remove('character-card-selected');
    });
  });
  $(document).on('click', updateMobileSelectionCard);
}

function hideContextMenu() {
  $(contextMenuID).removeClass('show').hide();
}

function updateMobileSelectionCard() {
  if (selectedCard != undefined) {
    let mobileRemoval = selectedCard.querySelector('.character-status-card-removal-button-mobile-container');
    if (mobileRemoval != undefined && !mobileRemoval.classList.contains('d-none')) {
      mobileRemoval.classList.add('d-none');
    }
    selectedCard = undefined;
  }
}

function addContextMenuOptionEventHandlers() {
  document.getElementById('character-card-open-stat-link-row')?.addEventListener('mousedown', function (event) {
    swapURL(event, selectedCharacterName, false);
  });
  document.getElementById('character-card-open-stat-link-new-tab-row')?.addEventListener('mousedown', function (event) {
    swapURL(event, selectedCharacterName, true);
  });
  document
    .getElementById('character-card-open-stat-link-new-window-row')
    ?.addEventListener('mousedown', function (event) {
      openURL(event, selectedCharacterName);
    });
  document.getElementById('remove-favorite-character-row')?.addEventListener('mousedown', function (event) {
    removeCharacterFromFavorites(selectedCharacterName);
  });
}

function removeCharacterFromFavorites(characterName: string) { }

function isMobileScreen() {
  return window.innerWidth <= 767;
}
