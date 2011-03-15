<?
    defined('_JEXEC') or die('Restricted access');
    
    $user = $this->user;
    $photos = $this->photos;
    $metadata = $this->metadata;
            
    // Отобразим выбранную фотографию, либо по умолчанию первую
    $id = JRequest::getInt('id');
    if (!empty($id))
    {
        foreach ($photos as $photo)
        {
            if ($photo->id == $id)
            {
                $currPhoto = $photo;
                break;
            }
        }
    }
    if (empty($currPhoto))
        $currPhoto = $photos[0];
    
    // Для удобства пихнем метаданные в текущуюю фотографию
    foreach ($metadata as $md_item)
    {
        if ($md_item['photo_id'] == $currPhoto->id)
        {
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
        <script type="text/javascript">
            
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
            
            /* Заполняет звёзды рейтинга */ 
            function fillStars() {
                var stars = $$('div[id^=star]');
                if ($('metadata_rating') != null) {                    
                    var rating = $('metadata_rating').value;                    
                    stars.removeClass('star_fill');
                    stars.removeClass('star_empty');
                    stars.forEach(function(el) {
                        if (el.id.toString().substr('star'.length, 1) <= rating)
                            el.addClass('star_was_fill');
                        else
                            el.addClass('star_was_empty');
                    });
                }
                else {
                    stars.addClass('star_empty');
                }
            }
            
            window.addEvent('domready', function() {                
                // Установим обработчики кнопок принятия
                $('accept_yes').addEvent('click', setAcceptedFlag.pass('yes'));
                $('accept_no').addEvent('click', setAcceptedFlag.pass('no'));
                $('accept_none').addEvent('click', setAcceptedFlag.pass('none'));
                
                // Подсветим флаг принятия
                if ($('metadata_accepted') != null) {
                    var metadata_accepted = $('metadata_accepted').value;
                    $$('a[id^=accept_]').removeClass('minibutton_selected');
                    $('accept_' + metadata_accepted).addClass('minibutton_selected');
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
                        fillStars();
                    });
                    el.addEvent('click', setRating.pass(el.id.toString().substr('star'.length, 1)));
                });
                
                // Заполним звёзды рейтинга                
                fillStars();
                
                // Установим обработчик кнопки сохранения комментариев
                $('save').addEvent('click', setComments);
            });                        
            
            /* Установка флага принятия для текущей фотографии */
            function setAcceptedFlag(flag) {
                var id = $('id').value;
                if (id == '') {
                    alert('Пожалуйста, выберите фотографию!');
                    return;
                }                                        
                
                var req = new Request({
                    url: 'index.php?option=com_lrgallery&task=photos.setAcceptedFlag&format=json',
                    onRequest: function() {
                        // Во время обработки запроса покажем анимацию
                        $('accept_loader').setStyle('visibility', 'visible');
                    },
                    onSuccess: function(result) {
                        // Скроем анимацию
                        $('accept_loader').setStyle('visibility', 'hidden');
                        
                        // Разберем ответ в формате JSON
                        var response = JSON.decode(result);
                        if (!response.error) {
                            // Если всё ок, подсветим выбранную кнопку
                            var flag = response.meta;
                            $$('a[id^=accept_]').removeClass('minibutton_selected');
                            $('accept_' + flag).addClass('minibutton_selected');
                            
                            if ($('metadata_accepted') == null) {
                                var accepted_input = new Element('input', {
                                    'type': 'hidden',
                                    'id':   'metadata_accepted',
                                    'name': 'metadata_accepted'
                                });
                                $(document.body).adopt(accepted_input);
                            }
                        }
                        else {
                            alert('При установке флага произошла ошибка. Пожалуйста, обратитесь к администратору');
                        }
                    }
                });
                
                req.send('id=' + id + '&flag=' + flag);                
            }
            
            /* Установка рейтинга текущей фотографии */
            function setRating(rating) {
                var id = $('id').value;
                if (id == '') {
                    alert('Пожалуйста, выберите фотографию!');
                    return;
                }                                        
                
                var req = new Request({
                    url: 'index.php?option=com_lrgallery&task=photos.setRating&format=json',
                    onRequest: function() {
                        // Во время обработки запроса покажем анимацию
                        $('rating_loader').setStyle('visibility', 'visible');
                    },
                    onSuccess: function(result) {
                        // Скроем анимацию
                        $('rating_loader').setStyle('visibility', 'hidden');
                        
                        // Разберем ответ в формате JSON
                        var response = JSON.decode(result);
                        if (!response.error) {
                            // Если всё ок, заполним звёзды
                            var rating = response.meta;
                            if ($('metadata_rating') == null) {
                                var rating_input = new Element('input', {
                                    'type': 'hidden',
                                    'id':   'metadata_rating',
                                    'name': 'metadata_rating'
                                });
                                $(document.body).adopt(rating_input);
                            }
                            $('metadata_rating').value = rating;
                            fillStars();
                        }
                        else {
                            alert('При установке рейтинга произошла ошибка. Пожалуйста, обратитесь к администратору');
                        }
                    }
                });
                
                req.send('id=' + id + '&rating=' + rating);
            }
            
            /* Запись комментариев текущей фотографии */
            function setComments() {
                var id = $('id').value;
                if (id == '') {
                    alert('Пожалуйста, выберите фотографию!');
                    return;
                }                                        
                
                var req = new Request({
                    url: 'index.php?option=com_lrgallery&task=photos.setComments&format=json',
                    onRequest: function() {
                        // Во время обработки запроса покажем анимацию
                        $('comments_loader').setStyle('visibility', 'visible');
                    },
                    onSuccess: function(result) {
                        // Скроем анимацию
                        $('comments_loader').setStyle('visibility', 'hidden');
                        
                        // Разберем ответ в формате JSON
                        var response = JSON.decode(result);
                        if (!response.error) {
                            
                        }
                        else {
                            alert('При записи комментариев произошла ошибка. Пожалуйста, обратитесь к администратору');
                        }
                    }
                });
                
                var comments = $('comments').value;
                req.send('id=' + id + '&comments=' + comments);
            }
            
        </script>
        
    </head>
    <body>
        <div id="header">
            <div id="caption_title">
                Отдых в Швейцарии
            </div>
            <div id="caption_date">
                (08.01.2011 11:03:47)
            </div>
        </div>
        <div class="clear"></div>

        <div id="content">
            <div id="imagebox">
                <img src="<? echo $currPhoto->base . "/" . $currPhoto->file_name; ?>" />
            </div>
            <div id="metadata">												
                <div class="acceptbox_caption">					
					Нравится?
                </div>
                <div class="clear"></div>
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
                <div class="clear"></div>

                <div class="ratingbox_caption">
					Ваша оценка:
                </div>
                <div class="clear"></div>
                <div id="ratingbox">					
                    <div class="star star_empty" id="star1"></div>
                    <div class="star star_empty" id="star2"></div>
                    <div class="star star_empty" id="star3"></div>
                    <div class="star star_empty" id="star4"></div>
                    <div class="star star_empty" id="star5"></div>
                </div>
                <div class="loader" id="rating_loader"></div>
                <div class="clear"></div>

                <div class="commentbox_caption">
					Комментарии:
                </div>
                <div id="commentbox">
                    <textarea id="comments" cols="20" rows="20"><? echo $currPhoto->metadata['comments']; ?></textarea>
                </div>                
                <div class="clear"></div>

                <a id="save" href="javascript:;" class="minibutton btn-download">
                    <span>
                        <span class="icon icon_save"></span>
                                                    Сохранить
                    </span>
                </a>
                <div class="loader" id="comments_loader"></div>
                <div class="clear"></div>
            </div>
        </div>
        <div class="clear"></div>

        <div id="footer">
            <div id="nav">
                <div class="nav_controls">
                    <div class="nav_first"></div>
                    <div class="nav_prev"></div>
                    <div class="nav_space"></div>
                    <div class="nav_next"></div>
                    <div class="nav_last"></div>
                </div>
            </div>
            <div class="clear"></div>

            <div id="thumbs">
<?
            foreach ($photos as $photo)
            {
?>
                <div class="thumb">
                    <img src="<? echo $photo->base . "/" . $photo->file_name; ?>" />
                </div>
<?
            }
?>                                               
            </div>
        </div>
        <div class="clear"></div>
        
        <input type="hidden" name="id" id="id" value="<? echo $currPhoto->id; ?>">
<?
    // Выведем все метаданные текущей фотографии
    if (!empty($currPhoto->metadata))
    {
        foreach ($currPhoto->metadata as $key => $value)
        {
?>
        <input type="hidden" name="metadata_<? echo $key; ?>" id="metadata_<? echo $key; ?>" value="<? echo $value; ?>" />
<?        
        }
    }
?>        
    </body>
</html>
