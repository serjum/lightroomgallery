<?php
    defined('_JEXEC') or die('Restricted access');


    jimport('joomla.application.component.controlleradmin');

    class LrgalleryControllerPhotos extends JControllerAdmin 
    {
        public function getModel($name = 'photo', $prefix = 'lrgalleryModel') 
        {
            $model = parent::getModel($name, $prefix, array('ignore_request' => true));
            return $model;
        }
    }
?>

