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
?>

<html lang="ru">
    <head>
        <meta http-equiv="content-type" content="text/html; charset=utf-8">
        <title>Веб-галерея Софтлит</title>

        <link rel="stylesheet" type="text/css" href="media/lrgallery/css/lrgallery.css" />
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
                <div class="clear"></div>

                <div class="ratingbox_caption">
					Ваша оценка:
                </div>
                <div class="clear"></div>
                <div id="ratingbox">					
                    <div class="star star_fill"></div>
                    <div class="star star_fill"></div>
                    <div class="star star_fill"></div>
                    <div class="star star_fill"></div>
                    <div class="star star_empty"></div>
                </div>
                <div class="clear"></div>

                <div class="commentbox_caption">
					Комментарии:
                </div>
                <div id="commentbox">
                    <textarea cols="20" rows="20"></textarea>
                </div>
                <div class="clear"></div>

                <a id="save" href="javascript:;" class="minibutton btn-download">
                <span>
                    <span class="icon icon_save"></span>
						Сохранить
                </span>
                </a>
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
    </body>
</html>
