$(document).ready(function () {
    initializeWeaponTableData();
});

function initializeWeaponTableData() {
    let weapon = { name: "orion", kills: 20, shots: 1000 };
    let table = document.getElementById("weaponTable");
    let tableBody = table.getElementsByTagName("tbody")[0];

    for (let i = 0; i < 5; i++) {
        let row = tableBody.insertRow(i);
        let cell1 = row.insertCell(0);
        let cell2 = row.insertCell(1);
        let cell3 = row.insertCell(2);
        let cell1Text = document.createTextNode(weapon.name);
        let cell2Text = document.createTextNode(weapon.kills);
        let cell3Text = document.createTextNode(weapon.shots);
        cell1.appendChild(cell1Text);
        cell2.appendChild(cell2Text);
        cell3.appendChild(cell3Text);
    }

    //setMobileHeaderTexts(table);
}
