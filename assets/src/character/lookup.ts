import { show as showLoadingScreen } from './../loading-screen.js';

let contextMenuID = '#character-card-context-menu';
let selectedCharacterName: string;
let selectedCard: HTMLElement | undefined;

window.addEventListener('load', (event) => {
  searchCharacter();
  addContextMenuEventHandlers();
  addCharacterCardClick();
  addDocumentClickEvents();
});

window.addEventListener('phx:character_card_change', (event) => {
  addCharacterCardClick();
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

function isEventTargetADeleteButtonClick(event: JQuery.ClickEvent) {
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

      //add data to menu options
      let removeID = selectedCard.querySelector(".character-status-card-removal-button")?.getAttribute("phx-value-id")!;
      document.getElementById("remove-favorite-character-row")?.setAttribute("phx-value-id", removeID);

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
    event.preventDefault();
    return false; //blocks default Webbrowser right click menu
  }
}

function addCharacterCardClick() {
  document.querySelectorAll('.character-status-card').forEach((card) => {
    let cardElement = card as HTMLElement;

    //remove and add RIGHT mouse click handler
    cardElement.removeEventListener('contextmenu', characterCardRightMouseClick);
    cardElement.addEventListener('contextmenu', characterCardRightMouseClick);
  });

  document.querySelectorAll('.status-card-section-header').forEach((header) => {
    header.removeEventListener('click', handleSectionHeaderClickEvent);
    header.addEventListener('click', handleSectionHeaderClickEvent);
  });
}

function handleSectionHeaderClickEvent(event: Event) {
  let target = event.target as HTMLElement;
  let chevron;
  if (!target.classList.contains("status-card-section-header")) {
    target = target.closest(".status-card-section-header")!;
  }
  chevron = target.querySelector('.fa-chevron-up') as HTMLElement;

  $(chevron).toggleClass('down');
}

function addDocumentClickEvents() {
  $(document).on('mouseup', function () {
    hideContextMenu();
    document.querySelectorAll('.character-card-selected').forEach((card) => {
      card.classList.remove('character-card-selected');
    });
  });
  $(document).on('click', updateMobileSelectionCard);
  $(document).on('click', 'a.character-status-card', function (event) {
    //make sure it's not a removal anotherwise prevent page change
    if (isEventTargetADeleteButtonClick(event)) {
      event.preventDefault();
    }
  });
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

function addContextMenuEventHandlers() {
  document.getElementById('character-card-open-stat-link-row')?.addEventListener('click', function (event) {
    swapURL(event, selectedCharacterName, false);
  });
  document.getElementById('character-card-open-stat-link-new-tab-row')?.addEventListener('click', function (event) {
    swapURL(event, selectedCharacterName, true);
  });
  document
    .getElementById('character-card-open-stat-link-new-window-row')
    ?.addEventListener('click', function (event) {
      openURL(event, selectedCharacterName);
    });
  document.getElementById('character-card-open-latest-session-row')?.addEventListener('click', function (event) {
    swapURL(event, selectedCharacterName + "/sessions/latest", false);
  });
  document.getElementById('character-card-open-latest-session-new-tab-row')?.addEventListener('click', function (event) {
    swapURL(event, selectedCharacterName + "/sessions/latest", true);
  });
  document.getElementById('character-card-open-latest-session-new-window-row')?.addEventListener('click', function (event) {
    openURL(event, selectedCharacterName + "/sessions/latest");
  });
}

function isMobileScreen() {
  return window.innerWidth <= 767;
}
