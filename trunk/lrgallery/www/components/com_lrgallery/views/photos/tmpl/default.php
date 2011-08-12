<?
defined('_JEXEC') or die('Restricted access');

$user = $this->user;
$photos = $this->photos;
$metadata = $this->metadata;

// Отобразим выбранную фотографию, либо по умолчанию первую
$id = JRequest::getInt('id');
if (!empty($id)) {
    foreach ($photos as $photo) {
        if ($photo->id == $id) {
            $currPhoto = $photo;
            break;
        }
    }
}
if (empty($currPhoto))
    $currPhoto = $photos[0];

// Для удобства пихнем метаданные в текущую фотографию
foreach ($metadata as $md_item) {
    if ($md_item['photo_id'] == $currPhoto->id) {
        $currPhoto->metadata[$md_item['name']] = $md_item['value'];
    }
}

?>

<html lang="ru">
    <head>
        <meta http-equiv="content-type" content="text/html; charset=utf-8" />
        <title>Веб-галерея Софтлит</title>

        <link rel="stylesheet" type="text/css" href="media/lrgallery/css/lrgallery.css" />

        <script type="text/javascript" src="media/system/js/mootools-core.js"></script>
        <script type="text/javascript" src="media/system/js/mootools-more.js"></script>
        <script type="text/javascript" src="media/lrgallery/js/slide.js"></script>
        <script type="text/javascript">
            
            var slider;
            var currThumb;
            var photoFx;
            
            /* Удаление лишних пробелов и др. из строки */
            function trimStr (s) {
                s = s.replace(/^\s+/, '');
                for (var i = s.length - 1; i >= 0; i--) {
                    if (/\S/.test(s.charAt(i))) {
                        s = s.substring(0, i + 1);
                        break;
                    }
                }
                return s;
            }
            
            window.addEvent('domready', function() {                
                // Установим обработчики кнопок принятия
                $('accept_yes').addEvent('click', setAcceptedFlag.pass('yes'));
                $('accept_no').addEvent('click', setAcceptedFlag.pass('no'));
                $('accept_none').addEvent('click', setAcceptedFlag.pass('none'));
                
                // Подсветим флаг принятия
                if ($('metadata_accepted') != null) {
                    var metadata_accepted = $('metadata_accepted').value;
                    if (metadata_accepted != null && metadata_accepted != "") {
                        $$('a[id^=accept_]').removeClass('minibutton_selected');
                        $('accept_' + metadata_accepted).addClass('minibutton_selected');
                    }                    
                }              
                
                // Установим обработчики звёзд рейтинга
                var stars = $$('div[id^=star]');
                stars.forEach(function(el) {
                    el.addEvent('mouseover', function(maxStar) {
                        var maxNum = maxStar.target.id.toString().substr('star'.length, 1);
                        stars.forEach(function(currStar) {
                            var currNum = currStar.id.toString().substr('star'.length, 1);                            
                            if (currNum <= maxNum) {
                                currStar.removeClass('star_was_empty');
                                currStar.removeClass('star_was_fill');
                                currStar.removeClass('star_empty');
                                currStar.addClass('star_fill');
                            }
                            else {
                                currStar.removeClass('star_was_empty');
                                currStar.removeClass('star_was_fill');
                                currStar.removeClass('star_fill');
                                currStar.addClass('star_empty');
                            }
                        })
                    });
                    el.addEvent('mouseleave', function(maxStar) {
                        stars.removeClass('star_fill');
                        stars.removeClass('star_empty');
                        displayRating($('metadata_rating').value);
                    });
                    el.addEvent('click', setRating.pass(el.id.toString().substr('star'.length, 1)));
                });
                
                // Заполним звёзды рейтинга
                if ($('metadata_rating') != null) {
                    displayRating($('metadata_rating').value);
                }                
                
                // Установим обработчик кнопки сохранения комментариев
                $('save').addEvent('click', setComments);
                
                // Установим обработчики для превью фотографий
                $$('div[id^=thumb_]').forEach(function(thumb) {
                    var thumbId = thumb.id.toString();
                    var photoId = thumbId.substr('thumb_'.length, thumbId.length - 'thumb_'.length);
                    thumb.addEvent('click', setCurrPhoto.pass(photoId));
                });
                
                // Подсветим текущую фотографию
                highlightThumb($(id).value);
                
                // Подсветка превью при наведении
                $$('div[id^=thumb_]').forEach(function(thumb) {
                    var thumbId = thumb.id.toString();
                    var photoId = thumbId.substr('thumb_'.length, thumbId.length - 'thumb_'.length);
                    thumb.addEvent('mouseover', function(){
                        highlightThumb(photoId, null);
                    });
                    thumb.addEvent('mouseleave', function(){
                        highlightThumb(null, photoId);
                    });
                });
                
                // Добавим слайдер
                currThumb = $('thumb_' + $('currPhoto').value);
                slider = new Fx.Scroll('thumbs_container', {
                    duration:   700,
                    transition: Fx.Transitions.Back.easeOut
                });
                
                // Добавим обработчик навигационных кнопок
                $('nav_first').addEvent('click', function(){
                    switchPhoto('first');                    
                });
                $('nav_prev').addEvent('click', function(){
                    switchPhoto('prev');                    
                });
                $('nav_next').addEvent('click', function(){
                    switchPhoto('next');
                });
                $('nav_last').addEvent('click', function(){
                    switchPhoto('last');
                });
                
                // Эффект плавного появления фотографии
                photoFx = new Fx.Tween('currPhoto', {
                    duration: 125,
                    transition: 'quad:out',
                    link: 'chain',
                    property: 'opacity'
                });
                
                // Добавим обработчик кнопки готовности
                $('ready_button').addEvent('click', function(){
                    notifyReady();
                });
            });
            
            /* Отображение анимации прогресса сохранения, либо отметки успешного сохранения */ 
            function displayLoader(id, mode){
                var loader = $(id);
                if (loader == null)
                    return;
                
                switch (mode) {
                    case 'progress':
                        loader.setStyle('visibility', 'visible');
                        loader.setStyle('background', "url('/media/lrgallery/images/loader.gif')");
                        loader.title = 'Идёт сохранение...';
                        break;
                    case 'saved':
                        loader.setStyle('visibility', 'visible');
                        loader.setStyle('background', "url('/media/lrgallery/images/saved.png') no-repeat");
                        loader.title = 'Сохранено';
                        break;
                    case 'none':                    
                    default:
                        loader.setStyle('visibility', 'hidden');
                        loader.title = '';
                        break;
                }
            }
            
            /* Получение значения поля метаданных фотографии */
            function getMetadata(id, meta, loader, callback) {
                if (id == '') {
                    alert('Пожалуйста, выберите фотографию!');
                    return;
                }                                                        
                var req = new Request({
                    url: 'index.php?option=com_lrgallery&task=photos.getMetaValue&format=json',
                    onRequest: loader,
                    onSuccess: function(result) {
                        var response = JSON.decode(result);
                        callback(response);
                    }
                }).send('id=' + id + '&meta=' + meta);
            }
            
            /* Установка значения поля метаданных фотографии */
            function setMetadata(id, meta, value, loader, callback) {
                if (id == '') {
                    alert('Пожалуйста, выберите фотографию!');
                    return;
                }                                                        
                var req = new Request({
                    url: 'index.php?option=com_lrgallery&task=photos.setMetaValue&format=json',
                    onRequest: loader,
                    onSuccess: function(result) {                       
                        var response = JSON.decode(result);
                        callback(response);
                    }
                }).send('id=' + id + '&meta=' + meta + '&value=' + value);
            }
            
            /* Получение флага принятия для фотографии */
            function getAcceptedFlag() {
                var id = $('id').value;
                if (id == '') {
                    alert('Пожалуйста, выберите фотографию!');
                    return;
                }
                getMetadata(id, 'accepted', null, function(response) {
                    if (!response.error) {
                        var flag = response.meta;
                        displayAcceptedFlag(flag);
                    }
                    else {
                        alert('При получении флага произошла ошибка. Пожалуйста, обратитесь к администратору');
                    }
                });
            }
            
            /* Отображение флага принятия */ 
            function displayAcceptedFlag(flag) {
                if ($('metadata_accepted') == null) {
                    var accepted_input = new Element('input', {
                        'type':     'hidden',
                        'id':       'metadata_accepted',
                        'name':     'metadata_accepted',
                        'value':    flag
                    });
                    $(document.body).adopt(accepted_input);
                }
                else if($('metadata_accepted').value != flag) {
                    $('metadata_accepted').value = flag;
                }
                flag = $('metadata_accepted').value;
                
                $$('a[id^=accept_]').removeClass('minibutton_selected');
                $('accept_' + flag).addClass('minibutton_selected');                
            }
            
            /* Установка флага принятия для текущей фотографии */
            function setAcceptedFlag(flag) {
                var id = $('id').value;
                setMetadata(id, 'accepted', flag, 
                function(){
                    // Во время обработки запроса покажем анимацию
                    displayLoader('accept_loader', 'progress');
                },
                function(response) {
                    // Отобразим ОК
                    displayLoader('accept_loader', 'saved');
                        
                    if (!response.error) {
                        // Если всё ок, подсветим выбранную кнопку
                        var flag = response.meta;
                        displayAcceptedFlag(flag);
                    }
                    else {
                        alert('При установке флага произошла ошибка. Пожалуйста, обратитесь к администратору');
                    }
                }
            );                                
            }
            
            /* Получение рейтинга для фотографии */
            function getRating() {
                var id = $('id').value;
                if (id == '') {
                    alert('Пожалуйста, выберите фотографию!');
                    return;
                }
                
                getMetadata(id, 'rating', null, function(response) {
                    if (!response.error) {
                        // Если всё ок, подсветим выбранную кнопку
                        var rating = response.meta;
                        displayRating(rating);
                    }
                    else {
                        alert('При получении рейтинга произошла ошибка. Пожалуйста, обратитесь к администратору');
                    } 
                });                
            }
            
            /* Отображение рейтинга */ 
            function displayRating(rating) {
                if ($('metadata_rating') == null) {
                    var rating_input = new Element('input', {
                        'type':     'hidden',
                        'id':       'metadata_rating',
                        'name':     'metadata_rating',
                        'value':    rating
                    });
                    $(document.body).adopt(rating_input);
                }
                else if ($('metadata_rating').value != rating) {
                    $('metadata_rating').value = rating;
                }
                rating = $('metadata_rating').value;
                
                var stars = $$('div[id^=star]');
                if (rating != null) {
                    stars.removeClass('star_fill');
                    stars.removeClass('star_empty');
                    stars.removeClass('star_was_fill');
                    stars.removeClass('star_was_empty');
                    stars.forEach(function(el) {
                        if (el.id.toString().substr('star'.length, 1) <= rating) {
                            el.addClass('star_was_fill');   
                        }                            
                        else {
                            el.addClass('star_was_empty');
                        }
                    });
                }
                else {
                    stars.addClass('star_empty');
                }                                    
            }
            
            /* Установка рейтинга текущей фотографии */
            function setRating(rating) {
                var id = $('id').value;
                if (id == '') {
                    alert('Пожалуйста, выберите фотографию!');
                    return;
                }                                        
                
                setMetadata(id, 'rating', rating, 
                function(){
                    // Во время обработки запроса покажем анимацию
                    displayLoader('rating_loader', 'progress');
                },
                function(response) {
                    // Отобразим ОК
                    displayLoader('rating_loader', 'saved');
                        
                    if (!response.error) {
                        // Если всё ок, заполним звёзды
                        var rating = response.meta;
                        displayRating(rating);
                    }
                    else {
                        alert('При установке рейтинга произошла ошибка. Пожалуйста, обратитесь к администратору');
                    }
                }
            );                                 
            }
            
            /* Получение комментариев для фотографии */
            function getComments() {
                var id = $('id').value;
                if (id == '') {
                    alert('Пожалуйста, выберите фотографию!');
                    return;
                }
                getMetadata(id, 'comments', null, function(response) {
                    if (!response.error) {
                        displayComments(response.meta);
                    }
                    else {
                        alert('При получении комментариев произошла ошибка. Пожалуйста, обратитесь к администратору');
                    }
                });
            }
                                                            
            /* Отображение комментариев для фотографии */
            function displayComments(comments) {
                $('comments').value = comments;
            }
            
            /* Запись комментариев текущей фотографии */
            function setComments() {
                var id = $('id').value;
                if (id == '') {
                    alert('Пожалуйста, выберите фотографию!');
                    return;
                }                                        
                
                var comments = $('comments').value;
                setMetadata(id, 'comments', comments, 
                    function(){
                        // Во время обработки запроса покажем анимацию
                        displayLoader('comments_loader', 'progress');
                    },
                    function(response) {
                        // Отобразим ОК
                        displayLoader('comments_loader', 'saved');

                        // Разберем ответ в формате JSON
                        var response = JSON.decode(result);
                        if (!response.error) {

                        }
                        else {
                            alert('При записи комментариев произошла ошибка. Пожалуйста, обратитесь к администратору');
                        }
                    }
                );                                
            }
            
            /* Получение названия фотографии */
            function getName() {
                var id = $('id').value;
                if (id == '') {
                    alert('Пожалуйста, выберите фотографию!');
                    return;
                }
                getMetadata(id, 'name', null, function(response) {
                    if (!response.error) {
                        displayName(response.meta);
                    }
                    else {
                        alert('При получении названии фотографии произошла ошибка. Пожалуйста, обратитесь к администратору');
                    }
                });
            }
                                                            
            /* Отображение названия фотографии */
            function displayName(name) {
                $('caption_title').innerHTML = name;
            }                        
            
            /* Получение даты фотографии */
            function getDatetime() {
                var id = $('id').value;
                if (id == '') {
                    alert('Пожалуйста, выберите фотографию!');
                    return;
                }
                getMetadata(id, 'datetime', null, function(response) {
                    if (!response.error) {
                        displayDatetime(response.meta);
                    }
                    else {
                        alert('При получении даты фотографии произошла ошибка. Пожалуйста, обратитесь к администратору');
                    }
                });
            }
                                                            
            /* Отображение названия фотографии */
            function displayDatetime(datetime) {
                $('caption_date').innerHTML = datetime;
            }                      
        
            /* Устанавливает текущую фотографию */
            function setCurrPhoto(id) {
                var photoSrc = $('photoBase').value + "/" + $('thumb_' + id).getAttribute('rel');
                
                // Плавно сменим фотографию
                photoFx.onComplete = function(){
                    $('currPhoto').src = photoSrc;
                    var upFx = new Fx.Tween('currPhoto', {
                        duration: 125,
                        transition: 'quad:in',
                        link: 'chain',
                        property: 'opacity'
                    });
                    upFx.start(0, 1);
                    //$('currPhoto').fade('in');
                }
                photoFx.start(1, 0);
                
                prevId = $('id').value;
                $('id').value = id;
                
                // Уберем затемнение с текущей фотографии
                highlightThumb(id, prevId);
                
                getName();
                getDatetime();
                getAcceptedFlag();
                getRating();
                getComments();
                
            }
            
            /* Подсвечивает выбранную фотографию и затемняет предыдущую */
            function highlightThumb(id, prevId, opacity) {
                if (opacity == null)
                    opacity = 0.85;
                if ($('darken_' + prevId) != null) {
                    $('darken_' + prevId).tween('opacity', opacity.toString());
                }
                if ($('darken_' + id) != null) {
                    $('darken_' + id).tween('opacity', '0');
                }                
            }
            
            /* Переключение на следующую/предыдущую/первую/последнюю фотографию */
            function switchPhoto(where) {
                
                // Переберем ID всех превью
                var ids = [];
                $$('div[id^=thumb_]').forEach(function(thumb) {
                    var photoId = thumb.id.substr('thumb_'.length, thumb.id.length - 'thumb_'.length);
                    ids.push(photoId);
                });
                
                // Опеределим текущий и следующий ID
                slider.cancel();
                var currId = $('id').value;
                var switchId = currId;                
                switch (where) {
                    case 'first':
                        switchId = ids[0];
                        slider.toLeft();
                        break
                    case 'prev':
                        switchId = ids[ids.indexOf(currId) - 1];
                        if (($('thumb_' + switchId).offsetParent.clientWidth - $('thumb_' + switchId).offsetLeft) > screen.width/2) {
                            slider.start(slider.element.scrollLeft - 105, 0);
                        }
                        break;
                    case 'next':
                        switchId = ids[ids.indexOf(currId) + 1];
                        if ($('thumb_' + switchId).offsetLeft > screen.width/2) {
                            slider.start(slider.element.scrollLeft + 105, 0);
                        }
                        break;
                    case 'last':
                        switchId = ids[ids.length - 1];
                        slider.toRight();
                        break;
                    default:
                        break;
                }
                
                
                // Переключим текущую фотографию
                setCurrPhoto(switchId);               
            }
            
            /* Оповещение о готовности пользователя */
            function notifyReady() {
                var req = new Request({
                    url: 'index.php?option=com_lrgallery&task=photos.notifyReady&format=json',
                    onRequest: function(){
                        displayLoader('ready_loader', 'progress');
                    },                    
                    onSuccess: function(result) {
                        displayLoader('ready_loader', 'saved');
                        var response = JSON.decode(result);
                        if (!response.error) {
                            alert('Фотограф оповещён о вашей готовности');
                        }
                        else {
                            alert('Во процессе оповещения фотографа возникла ошибка:\n' + response.message + 
                                 '\n Пожалуйста, обратитесь к администратору');
                        }
                            
                    }
                }).send();
            }
        </script>

    </head>
    <body>
        <div id="header">
            <div id="thumbs_container">
                <div id="thumbs" style="width: <? echo 130 * count($photos); ?>;">
<?
                    foreach ($photos as $photo) 
                    {
?>
                        <div class="thumb" id ="thumb_<? echo $photo->id; ?>" rel="<? echo $photo->file_name; ?>">
                            <img src="<? echo $photo->base . "/" . $photo->file_name; ?>" />
                            <img id="darken_<? echo $photo->id; ?>" src="media/lrgallery/images/darken_small.png" class="darken_small"/>
                        </div>
<?
                    }
?>                                               
                </div>
            </div>
            <div class="clear"></div>
            
            <div id="nav">
                <div class="nav_controls">
                    <!--div class="nav_first" id="nav_first"></div>
                    <div class="nav_prev" id="nav_prev"></div>
                    <div class="nav_space"></div>
                    <div class="nav_next" id="nav_next"></div>
                    <div class="nav_last" id="nav_last"></div-->
                    <a id="nav_first" href="javascript:;" class="minibutton">
                        <span class="nav_arrow">
                            &#8676;
                        </span>                        
                    </a>
                    <a id="nav_prev" href="javascript:;" class="minibutton">
                        <span class="nav_arrow">
                            &larr;
                        </span>                        
                    </a>
                    <div class="nav_space"></div>
                    <a id="nav_next" href="javascript:;" class="minibutton">
                        <span class="nav_arrow">
                            &rarr;
                        </span>                        
                    </a>
                    <a id="nav_last" href="javascript:;" class="minibutton">
                        <span class="nav_arrow">
                            &#8677;
                        </span>                        
                    </a>
                </div>
            </div>
            <div class="clear"></div>                        
        </div>
        <div class="clear"></div>

        <div id="content">
            <!--div class="caption_container">
                <div id="caption_title">
                    <? echo $currPhoto->metadata['name']; ?>
                </div>
                <div id="caption_date">
                    (<? echo $currPhoto->metadata['datetime']; ?>)
                </div>
            </div>            
            <div class="clear"></div-->
            
            <div id="image_container">
                <div id="imagebox">
                    <img id="currPhoto" src="<? echo $currPhoto->base . "/" . $currPhoto->file_name; ?>" />
                </div>
                
                <div id="metadata">
                    <div class="rating_container">
                        <!--div class="ratingbox_caption">
                            Ваша оценка:
                        </div-->
                        <div id="ratingbox">					
                            <div class="star star_empty" id="star1"></div>
                            <div class="star star_empty" id="star2"></div>
                            <div class="star star_empty" id="star3"></div>
                            <div class="star star_empty" id="star4"></div>
                            <div class="star star_empty" id="star5"></div>
                        </div>
                        <div class="loader" id="rating_loader"></div>
                    </div>
                    <div class="clear"></div>

                    <div class="accept_container">                    
                        <!--div class="acceptbox_caption">					
                                                Нравится?
                        </div-->                    
                        <div id="acceptbox">										
                            <a id="accept_yes" href="javascript:;" class="minibutton btn-download">
                            <span>
                                <span class="icon icon_yes"></span>
                                                                Да
                            </span>
                            </a>
                            <a id="accept_no" href="javascript:;" class="minibutton btn-download">
                            <span>
                                <span class="icon icon_no"></span>
                                                                Нет
                            </span>
                            </a>
                            <a id="accept_none" href="javascript:;" class="minibutton btn-download">
                            <span>
                                <span class="icon icon_none"></span>
                                                                Не знаю
                            </span>
                            </a>
                        </div>
                        <div class="loader" id="accept_loader"></div>
                    </div>
                    <div class="clear"></div>

                    <div class="comment_container">
                        <!--div class="commentbox_caption">
                                                Комментарии:
                        </div-->
                        <div id="commentbox">
                            <textarea id="comments" rows="10" cols="15"><? echo $currPhoto->metadata['comments']; ?></textarea>
                        </div>
                        <div class="clear"></div>
                        <a id="save" href="javascript:;" class="minibutton btn-download">
                            <span>
                                <span class="icon icon_save"></span>
                                Сохранить
                            </span>
                        </a>
                        <div class="loader" id="comments_loader"></div>
                    </div>
                    <div class="clear"></div>
                    
                    <div class="ready_button_container">
                        <div class="ready_button">
                            <a id="ready_button" href="javascript:;" class="minibutton btn-download">
                            <span>
                                <span class="icon icon_ready"></span>
                                Фотограф, готово!
                            </span>
                            </a>                            
                        </div>
                        <div class="loader" id="ready_loader"></div>
                    </div>
                </div>
                <div class="clear"></div>
            </div>                        
        </div>
        <div class="clear"></div>

        <div id="footer">                                    
            
        </div>
        <div class="clear"></div>

        <input type="hidden" name="photoBase" id="photoBase" value="<? echo $currPhoto->base; ?>">
        <input type="hidden" name="id" id="id" value="<? echo $currPhoto->id; ?>">
<?
// Выведем все метаданные текущей фотографии
if (!empty($currPhoto->metadata)) {
    foreach ($currPhoto->metadata as $key => $value) {
        ?>
                <input type="hidden" name="metadata_<? echo $key; ?>" id="metadata_<? echo $key; ?>" value="<? echo $value; ?>" />
                <?
            }
        }
        ?>        
        </body>
        </html>
