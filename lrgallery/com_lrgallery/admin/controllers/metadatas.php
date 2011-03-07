<?php
    defined('_JEXEC') or die('Restricted access');


    jimport('joomla.application.component.controlleradmin');

    class LrgalleryControllerMetadatas extends JControllerAdmin
    {
        public function getModel($name = 'metadata', $prefix = 'lrgalleryModel') 
        {
            $model = parent::getModel($name, $prefix, array('ignore_request' => true));
            return $model;
        }
    }
?>