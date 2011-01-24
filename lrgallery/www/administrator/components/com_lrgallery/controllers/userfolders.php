<?php
    defined('_JEXEC') or die('Restricted access');


    jimport('joomla.application.component.controlleradmin');

    class LrgalleryControllerUserfolders extends JControllerAdmin
    {
        public function getModel($name = 'userfolder', $prefix = 'lrgalleryModel') 
        {
            $model = parent::getModel($name, $prefix, array('ignore_request' => true));
            return $model;
        }
    }
?>