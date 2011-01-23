<?php

    defined('_JEXEC') or die('Restricted access');

    jimport('joomla.application.component.controller');
    
    class LrgalleryController extends JController
    {
        function display($cachable = false) 
        {
            JRequest::setVar('view', JRequest::getCmd('view', 'userfolders'));
            parent::display($cachable);
        }
    }

?>