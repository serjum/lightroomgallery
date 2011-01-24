<?php

    defined('_JEXEC') or die('Restricted access');

    jimport('joomla.application.component.controller');
    
    class LrgalleryController extends JController
    {
        function display($cachable = false) 
        {
            JRequest::setVar('view', JRequest::getCmd('view', 'photos'));
            parent::display($cachable);            
            HelloWorldHelper::addSubmenu('photos');
        }
    }

?>