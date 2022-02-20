export function handleSubPageNavLinkEvents() {
    //for each sub header nav
    var links = document.querySelectorAll(".subpage-nav");
    links.forEach(link => {
        //if there is a possible subpage, activate the current
        if (window.location.pathname != "/") {
            addOrRemoveActiveSubpage(link);
        }
    });

    function addOrRemoveActiveSubpage(link) {
        //initialize variables
        let primaryPage = window.location.pathname.split("/")[1].toLowerCase();
        let index = (primaryPage == "charcter") ? 2 : 3;
        let url = window.location.pathname.split("/")[index].toLowerCase();
        let inner = link.firstElementChild.innerHTML;
        let lowerLink = inner.toLowerCase();

        //if it's the current subpage add the active-subpage class
        if (lowerLink.includes(url) || lowerLink == url || url.includes(lowerLink)) {
            link.classList.add("active-subpage");

            //otherwise remove the active-subpage class
        } else {
            link.classList.remove("active-subpage");
        }
    }
}
