<?php
    defined('_JEXEC') or die;

    abstract class LrgalleryHelper
    {
        public static function addSubmenu($submenu) 
        {
            JSubMenuHelper::addEntry('Фотографии', 'index.php?option=com_lrgallery', $submenu == 'photos');
            JSubMenuHelper::addEntry('Папки пользователей', 'index.php?option=com_lrgallery&view=userfolders', $submenu == 'userfolders');
            JSubMenuHelper::addEntry('Поля метаданных', 'index.php?option=com_lrgallery&view=metas', $submenu == 'metas');
            JSubMenuHelper::addEntry('Метаданные', 'index.php?option=com_lrgallery&view=metadatas', $submenu == 'metadatas');

            $document = JFactory::getDocument();
            $document->addStyleDeclaration('.icon-48-meta {background-image: url(../media/com_lrgallery/images/meta48.png);}');
            $document->addStyleDeclaration('.icon-48-photo {background-image: url(../media/com_lrgallery/images/image48.png);}');
            $document->addStyleDeclaration('.icon-48-userfolder {background-image: url(../media/com_lrgallery/images/folder48.png);}');            
        }
    }
?>