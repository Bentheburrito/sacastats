// import { show as showLoadingScreen } from './../loading-screen.js';

let contextMenuID = '#character-card-context-menu';
let selectedCharacterName: string;
let selectedCard: HTMLElement | undefined;

window.addEventListener('load', (event) => {
  addCharacterCardClick();
  addDocumentClickEvents();
});

window.addEventListener('phx:character_card_change', (event) => {
  addCharacterCardClick();
});

function isEventTargetADeleteButtonClick(event: JQuery.ClickEvent) {
  let target = (event.target as HTMLElement);
  let classList = target.classList;
  return (
    (target.tagName.toLowerCase() == 'path' && target.parentElement?.classList.contains('fa-trash')) ||
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

function isMobileScreen() {
  return window.innerWidth <= 767;
}
