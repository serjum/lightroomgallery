<?php
    defined('_JEXEC') or die('Restricted access');


    jimport('joomla.application.component.controlleradmin');

    class LrgalleryControllerMetas extends JControllerAdmin
    {
        public function getModel($name = 'meta', $prefix = 'lrgalleryModel') 
        {
            $model = parent::getModel($name, $prefix, array('ignore_request' => true));
            return $model;
        }
    }
?>