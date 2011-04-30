<?php
    
    /*** Инициализируем Joomla Framework ***/
    define('_JEXEC', 1);
    define('DS', DIRECTORY_SEPARATOR);

    if (!defined('_JDEFINES')) {
        define('JPATH_BASE', dirname(dirname(dirname(__FILE__))));
        require_once JPATH_BASE . DS . 'includes' . DS . 'defines.php';
    }
    require_once JPATH_BASE . DS . 'includes' . DS . 'framework.php';
    
    $app = JFactory::getApplication('site');
    $app->initialise();

    // Подключаем нужные библиотеки
    jimport('joomla.filesystem.file');
    jimport('joomla.utilities.simplexml');
    jimport('joomla.application.component.helper');

    /*
     * Вспомогательный класс для работы с xml rpc
     */
    class PublishHelper {
        
        private $data = null;
        private $error = null;
                
        /*
         * Разбор содержимого XML
         */
        public function parse($xmlVar) {
            
            // Получим содержимое
            //$content = JRequest::getString($xmlVar, '', 'POST');
            $content = $_POST[$xmlVar];
            
            if (empty($content)) {
                $this->error = new JException('XML content is empty', 1);
                return $this->error;
            }

            // Попробуем разобрать его как XML
            $parser = new JSimpleXML();
            if (!$parser->loadString($content)) {
                $this->error = new JException('Error occured while parsing XML', 1);
                return $this->error;
            }
            
            // Найдём метод
            $method = $parser->document->methodName[0]->data();
            $this->data->method = $method;           
            
            // Найдём параметры
            $this->data->params = array();
            foreach ($parser->document->params[0]->children() as $param) {
                $keyValues = $param->value[0]->children();
                $keyValue = $keyValues[0];
                $this->data->params[$keyValue->name()] = $keyValue->data();
            }
            
            // Если в параметрах присутствует изображение, 
            // декодируем его из base64 и запишем во временный файл
            if (in_array('image', $this->data->params)) {
                $data = base64_decode($this->data->params['image']);
                $file = tempnam(sys_get_temp_dir(), 'lrgallery_');
                JFile::write($file, $data);
                
                $this->data->params['fileName'] = $file;
                unset($this->data->params['image']);                
            }
        }
        
        /*
         * Вызов метода, определённого в разобранном XML файле
         */
        public function call() {
            
            // Получим сервисный контроллер
            $controllerName = 'LrgalleryControllerService';
            define('JPATH_COMPONENT', JPATH_BASE . DS . 'components' . DS . 'com_lrgallery');
            require_once(JPATH_COMPONENT . DS . 'controllers' . DS . 'service.php');
            $controller = new $controllerName();
            
            // Выберем нужные параметры вызываемого метода при помощи рефлексии
            $method = new ReflectionMethod($controllerName, $this->data->method);
            $params = array();
            foreach ($method->getParameters() as $reflectionParam) {
                $params[] = $this->data->params[$reflectionParam->name];
            }
            
            // Вызовем метод с нужными параметрами
            $this->data->result = call_user_func_array(array($controllerName, $this->data->method), $params);
        }
        
        /*
         * Получение результата в формате XML
         */
        public function getXmlResult() {
            
        }
    }

?>
