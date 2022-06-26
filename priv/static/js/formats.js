const PREFERED_LANGUAGE = navigator.languages ? navigator.languages[0] : (navigator.language || navigator.userLanguage);
const PREFERED_TIME_ZONE = Intl.DateTimeFormat().resolvedOptions().timeZone;

export function addFormatsToPage() {
    addCommasToNumbers();
    formatDateTimes();
    secondsToHHMMSS();
    addPercents();

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
            if (!isNaN(date.charAt(0))) {
                try {
                    let dateTimeObject = new Date(getLocalDateStringWithTimeFromStrings(date, time));
                    const LONG_FORMATTER = new Intl.DateTimeFormat(PREFERED_LANGUAGE, {
                        year: 'numeric',
                        month: 'long',
                        day: 'numeric'
                    });

                    try {
                        dateTime.innerHTML = LONG_FORMATTER.format(dateTimeObject) + " @ " + dateTimeObject.toLocaleTimeString(PREFERED_LANGUAGE);
                    } catch (error) {
                        console.error(error);
                        console.error("LONG_FORMATTER: ");
                        console.error(LONG_FORMATTER);
                        console.error("dateTimeObject: ");
                        console.error(dateTimeObject);
                    }
                } catch (error) {
                    console.error(error);
                    console.error("Time variables not defined for: '" + dateTimeString + "'.");
                }
            }
        });
    }

    function getLocalDateStringWithTimeFromStrings(date, time) {
        let dateArr = date.split("-");
        let timeArr = time.split(":");

        return new Date(Date.UTC(dateArr[0], dateArr[1] - 1, dateArr[2], timeArr[0], timeArr[1], timeArr[2].split(".")[0])).toLocaleString('en-US', { timeZone: PREFERED_TIME_ZONE });
    }

    function addPercents() {
        //get every element with the percentage class and adds a '%' at the end
        let percents = document.querySelectorAll(".percentage");
        percents.forEach(percent => {
            //if there is no percent sign add one
            if (percent.innerHTML == "") {
                percent.innerHTML = "N/A";
            } else if (percent.innerHTML.slice(-1) != "%" && percent.innerHTML.slice(-1) != "A") {
                percent.innerHTML += "%";
            }
        });
    }

    function secondsToHHMMSS() {
        //get every element with the seconds-to-readable class and convert the string
        let seconds = document.querySelectorAll(".seconds-to-readable");
        const YEAR_SECOND = 31556952;
        const DAY_SECOND = 86400;
        const HOUR_SECOND = 3600;
        const MINUTE_SECOND = 60;

        seconds.forEach(second => {
            let secondFindingArray = second.innerHTML.split("</span>");
            let secondCount = +secondFindingArray[secondFindingArray.length - 1];

            //if it's a number
            if (!isNaN(secondCount)) {
                let time = "";
                let year;
                let day;
                let hour;
                let min;
                let sec;

                //add y d h m s values
                switch (true) {
                    case (secondCount >= YEAR_SECOND):
                        year = Math.floor(secondCount / YEAR_SECOND);
                        secondCount %= YEAR_SECOND;
                        day = Math.floor(secondCount / DAY_SECOND);
                        secondCount %= DAY_SECOND;
                        hour = Math.floor(secondCount / HOUR_SECOND);
                        time = year + "y " + ((day > 0) ? (day + "d ") : "") + ((hour > 0) ? (hour + "h") : "");
                        break;
                    case (secondCount >= DAY_SECOND):
                        day = Math.floor(secondCount / DAY_SECOND);
                        secondCount %= DAY_SECOND;
                        hour = Math.floor(secondCount / HOUR_SECOND);
                        time = day + "d " + ((hour > 0) ? (hour + "h") : "");
                        break;
                    case (secondCount >= HOUR_SECOND):
                        hour = Math.floor(secondCount / HOUR_SECOND);
                        secondCount %= HOUR_SECOND;
                        min = Math.floor(secondCount / MINUTE_SECOND);
                        time = hour + "h " + ((min > 0) ? (min + "m") : "");
                        break;
                    case (secondCount >= MINUTE_SECOND):
                        min = Math.floor(secondCount / MINUTE_SECOND);
                        sec = secondCount %= MINUTE_SECOND;
                        time = min + "m " + ((second > 0) ? (second + "s") : "");
                        break;
                    default: time = secondCount + "s";
                }
                second.innerHTML = time;
            }
        });
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
            let progressElement = $("#" + progressBar.id);
            if (progressElement.width() == 0 && !progressElement.is(":animated")) {
                progressElement.animate({ width: "" + finishedWidth + "%" }, 300);
            }
        }
    });
}
