<?php

    defined('_JEXEC') or die('Restricted access');

    jimport('joomla.application.component.controller');
    
    class lrgalleryController extends JController
    {
        function display($cachable = false) 
        {
            JRequest::setVar('view', JRequest::getCmd('view', 'photos'));
            parent::display($cachable);
        }
    }

?>