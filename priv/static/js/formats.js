const preferedLanguage = navigator.language;

export function addFormatsToPage() {
    addCommasToNumbers();
    formatDateTimes();

    function addCommasToNumbers() {
        //get every element with the number class and add proper commas
        let numbers = document.querySelectorAll(".number");
        numbers.forEach(number => {
            number.innerHTML = number.innerHTML.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
        });
    }

    function formatDateTimes() {
        let dateTimes = document.querySelectorAll(".date-time");
        dateTimes.forEach(dateTime => {
            let dateTimeString = dateTime.innerHTML;
            let date = dateTimeString.split(" ")[0];
            let time = dateTimeString.split(" ")[1];
            let dateTimeObject = new Date(getLocalDateStringWithTimeFromStrings(date, time));
            const longFormatter = new Intl.DateTimeFormat(preferedLanguage, {
                year: 'numeric',
                month: 'long',
                day: 'numeric',
            });

            dateTime.innerHTML = longFormatter.format(dateTimeObject) + " @ " + dateTimeObject.toLocaleTimeString();
        });
    }

    function getLocalDateStringWithTimeFromStrings(date, time) {
        let dateArr = date.split("-");
        let timeArr = time.split(":");
        return new Date(Date.UTC(dateArr[0], dateArr[1] - 1, dateArr[2], timeArr[0], timeArr[1], timeArr[2].split(".")[0])).toLocaleString(preferedLanguage, { timeZone: Intl.DateTimeFormat().resolvedOptions().timeZone });
    }
}

export function addAnimationToProgressBars() {
    let progressBars = document.querySelectorAll(".progress-bar");
    progressBars.forEach(function (progressBar, index) {
        var finishedWidth = progressBar.getAttribute("aria-valuenow");
        if (progressBar.id.indexOf("weapon") <= -1) {
            setTimeout(animateProgressBar, index * 500);
        } else {
            animateProgressBar()
        }
        function animateProgressBar() {
            $("#" + progressBar.id).animate({ width: "" + finishedWidth + "%" }, 300);
        }
    });
}
