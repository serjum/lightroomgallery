<?php
    // no direct access
    defined('_JEXEC') or die;

    jimport('joomla.application.component.controllerform');

    class LrgalleryControllerPhotos extends JControllerForm
    {
        /*
         * Установление флага принятия для фотографии
         */
        public function setAcceptedFlag()
        {
            echo "Hello from setAcceptedFlag()";
        }
        
        /*
         * Установка рейтинга фотографии
         */
        public function setRating()
        {
            
        }
        
        /*
         * Установка комментариев фотографии
         */
        public function setComments()
        {
            
        }        
    }
?>    