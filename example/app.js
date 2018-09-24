// Testing ti.mely 

var tabGroup = Ti.UI.createTabGroup();

Ti.App.addEventListener('memorywarning', function(e){
  console.log('MEMORY WARNING:', e);
  alert('Memory warning!');
});

tabGroup.addTab(createTab("ti.mely ", "ti.mely tests", "assets/images/tab1.png"));

tabGroup.open();

function createTab(title, message, icon) {
    var win = Ti.UI.createWindow({
        title: title,
        layout:'vertical',
        backgroundColor: '#fff'
    });
    var label = Ti.UI.createLabel({
        top: 20,
        text: message,
        color: '#333',
        font: {
            fontSize: 15
        }
    });

    win.add(label);

    var counter = 0;
    var counter2 = 0;
    var label_test = Ti.UI.createLabel({
        text: counter,
        top:20,
        color: '#111',
        font: {
            fontSize: 20,
            fontWeight: 'bold'
        }
    });
    win.add(label_test);

    var label_test2 = Ti.UI.createLabel({
        top: 20,
        text: counter2,
        color: '#111000',
        font: {
            fontSize: 20,
            fontWeight: 'bold'
        }
    });
    win.add(label_test2);

    var timely = require('ti.mely');


    var btn = Ti.UI.createButton({
        top:20,
        width:200,
        title: 'start 5sec timeout'
    });

    var timeoutTimer = null;
    btn.addEventListener('click', function(e){
        console.log('START 5 secs timeout');
        timeoutTimer = timely.createTimer();
        timeoutTimer.setTimeout(function(){
            console.log('TIMEOUT DONE');
            timeoutTimer = null;
        }, 5000, true);

    });

    win.add(btn);

    var btn2 = Ti.UI.createButton({
        top:20,
        width:200,
        title: 'start interval tests'
    });


    var intervaltimer = null;
    var intervaltimeout = null;
    btn2.addEventListener('click', function(e){

        counter = 0;
        
        intervaltimer = timely.createTimer();
        intervaltimer.setInterval(function(){
            counter++;
            label_test.text = counter;
            if(counter > 99999999999999){
                counter = 0;
            }
            if(counter % 100 == 0){
                intervaltimeout = timely.createTimer();
                intervaltimeout.setTimeout(function(){
                    counter2++;
                    label_test2.text = counter2;
                    console.log('DING! ', counter2, Date.now());
                    intervaltimeout = null;
                }, 1000);
            }
        }, 100);


    });

    win.add(btn2);

    var btn3 = Ti.UI.createButton({
        top:20,
        width:200,
        title: 'stop all'
    });

    btn3.addEventListener('click', function(e){

        console.log('stopping');
        if(intervaltimer!==null){
            intervaltimer.clearInterval();
        }
        if(intervaltimeout!==null){
            intervaltimeout.clearTimeout();
        }

        if(timeoutTimer!==null){
            timeoutTimer.clearTimeout();
        }
                
        timeoutTimer = null;
        intervaltimer = null;
        intervaltimeout = null;

    });

    win.add(btn3);


    var tab = Ti.UI.createTab({
        title: title,
        icon: icon,
        window: win
    });

    return tab;
}

