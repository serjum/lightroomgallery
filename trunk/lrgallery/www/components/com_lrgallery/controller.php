<?php

    defined('_JEXEC') or die('Restricted access');
 
    jimport('joomla.application.component.controller');
 
    class LrgalleryController extends JController
    {
        function display($cachable = false) 
        {
            $view = JRequest::getCmd('view', 'photos');
            JRequest::setVar('view', $view);
            parent::display($cachable);            
        }
    }
?>
