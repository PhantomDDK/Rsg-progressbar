var cancelledTimer = null;
var timer = null;

$('document').ready(function() {
    Progressbar = {};
    $('.container').hide();
    $('.watch').hide();
    $('.label').hide();
    var style = null;
    Progressbar.Progress = function(data) {
        clearTimeout(timer);
        clearTimeout(cancelledTimer);

        $('.label').text(data.label);
        $('.label').fadeIn('fast');
        $('.watch').fadeIn('fast');
        $('.container').fadeIn('fast', function() {
            
            const duration = parseInt(data.duration); // duration in seconds
            style = document.createElement('style');
            style.innerHTML = `
            .container.animate .half-right:after {
                animation-duration: ${duration/1000/2}s;
            }

            .container.animate .half-left:after {
                animation-duration: ${duration / 1000 / 2 }s;
                animation-delay: ${duration / 1000 / 2 }s;
            }
            `;

            document.head.appendChild(style);
            document.querySelector('.container').classList.add('animate');
            timer = setTimeout(()=>{  
                document.querySelector('.container').classList.remove('animate');
                $('.container').fadeOut('fast');
                $('.watch').fadeOut('fast');
                $('.label').fadeOut('fast');
                //remove style
                document.head.removeChild(style);

                $.post('https://progressbar/FinishAction', JSON.stringify({}));
            }, duration)
        });
        
    };

    Progressbar.ProgressCancel = function() {
        clearTimeout(timer);
        $('.watch').fadeOut('fast');
        $('.label').fadeOut('fast');
        $('.container').fadeOut('fast', function() {
            cancelledTimer = setTimeout(()=>{               
                document.querySelector('.container').classList.remove('animate');
                $.post('https://progressbar/CancelAction', JSON.stringify({}));
            },0)
        });
    };

    Progressbar.CloseUI = function() {
        $('.container').fadeOut('fast');
        $('.watch').fadeOut('fast');
        $('.label').fadeOut('fast');
        document.head.removeChild(style);
    };
    
    window.addEventListener('message', function(event) {
        switch(event.data.action) {
            case 'progress':
                Progressbar.Progress(event.data);
                break;
            case 'cancel':
                Progressbar.ProgressCancel();
                break;
        }
    });
});
