// frontend/src/App.jsx
import { useState, useEffect } from 'react';

import { useOceanSound } from './hooks/useOceanSound';
import { generateStepsAPI, generatePlanAPI, processUnplannedTaskAPI } from './services/api';
// import { INITIAL_LETTERS } from './data/constants'; 

import InitialView from './components/views/InitialView';
import StepsView from './components/views/StepsView';
import RoomView from './components/views/RoomView';
import DeckView from './components/views/DeckView';
import Mailbox from './components/features/Mailbox';
import FirstAid from './components/features/FirstAid';

export default function App() {
  const [view, setView] = useState('initial');
  const [userName, setUserName] = useState('');
  const [beanName, setBeanName] = useState('豆豆');
  const [userGoal, setUserGoal] = useState('');

  // 為了避免報錯，先給一個空的預設值
  const [letters, setLetters] = useState([]);
  const [generatedSteps, setGeneratedSteps] = useState([]);
  const [selectedSteps, setSelectedSteps] = useState([]);
  const [detailedPlan, setDetailedPlan] = useState({});
  const [monthlyPlan, setMonthlyPlan] = useState([]);
  const [todoList, setTodoList] = useState([]);
  const [energy, setEnergy] = useState(null);

  const [showMailbox, setShowMailbox] = useState(false);
  const [showFirstAid, setShowFirstAid] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [hasUnreadMail, setHasUnreadMail] = useState(false);
  const [selectedRecharge, setSelectedRecharge] = useState([]);

  // 如果 useOceanSound 還沒寫好，這行可能會報錯，可以先註解掉
  const { isPlaying, toggleSound } = useOceanSound();

  const handleGoalSubmit = async () => {
    setIsLoading(true);
    try {
      // 這裡會去呼叫我們寫在 services/api.js 的功能，然後打給 Rails！
      const data = await generateStepsAPI(userGoal);
      setGeneratedSteps(data?.steps || ['制定計畫', '執行行動', '休息']);
      setView('steps');
    } catch (e) {
      console.error(e);
      setGeneratedSteps(['制定計畫', '執行行動', '休息']);
      setView('steps');
    } finally {
      setIsLoading(false);
    }
  };

  const handleGeneratePlan = async () => {
    setIsLoading(true);
    const stepsToUse = selectedSteps.length > 0 ? selectedSteps : generatedSteps;
    try {
      const plan = await generatePlanAPI(userGoal, stepsToUse);
      setDetailedPlan(plan);
      const flatPlan = Object.values(plan).flat();
      setMonthlyPlan(flatPlan);
      setView('main');
    } catch (e) {
      console.error(e);
      setView('main');
    } finally {
      setIsLoading(false);
    }
  };

  const handleEnergySelect = (level) => {
    setEnergy(level);
    let tasks = [];
    if (level === 'high') {
      tasks = monthlyPlan.slice(0, 5).map((t, i) => ({ id: i, title: t, completed: false, time: 0, isRunning: false }));
    } else if (level === 'medium') {
      tasks = monthlyPlan.slice(0, 3).map((t, i) => ({ id: i, title: t, completed: false, time: 0, isRunning: false }));
    } else if (level === 'low') {
      const firstTask = monthlyPlan.length > 0 ? monthlyPlan[0] : '專注在當下，深呼吸';
      tasks = [{ id: 'low-task', title: firstTask, completed: false, time: 0, isRunning: false }];
    }
    setTodoList(tasks);
  };

  const toggleTimer = (id) => {
    setTodoList(prev => prev.map(t => t.id === id ? { ...t, isRunning: !t.isRunning } : t));
  };

  const completeTask = (task) => {
    setTodoList(prev => prev.map(t => t.id === task.id ? { ...t, completed: true, isRunning: false } : t));
  };

  useEffect(() => {
    const interval = setInterval(() => {
      setTodoList(list => list.map(t => t.isRunning ? { ...t, time: t.time + 1 } : t));
    }, 1000);
    return () => clearInterval(interval);
  }, []);

  return (
    <div className="min-h-screen grid place-items-center">
      <div className="w-full md:w-1/2 lg:w-1/3 min-h-[100dvh] relative shadow-2xl overflow-x-hidden bg-white">

        {view === 'initial' && (
          <InitialView
            userName={userName} setUserName={setUserName}
            beanName={beanName} setBeanName={setBeanName}
            userGoal={userGoal} setUserGoal={setUserGoal}
            selectedRecharge={selectedRecharge}
            toggleRecharge={(item) => setSelectedRecharge(prev => prev.includes(item) ? prev.filter(i => i !== item) : [...prev, item])}
            onSubmit={handleGoalSubmit}
            isLoading={isLoading}
          />
        )}

        {view === 'steps' && (
          <StepsView
            userName={userName} userGoal={userGoal}
            generatedSteps={generatedSteps}
            selectedSteps={selectedSteps}
            toggleStep={(step) => setSelectedSteps(prev => prev.includes(step) ? prev.filter(s => s !== step) : [...prev, step])}
            onBack={() => setView('initial')}
            onNext={handleGeneratePlan}
            isLoading={isLoading}
          />
        )}

        {view === 'main' && (
          <RoomView
            userName={userName} beanName={beanName}
            onSwitchToDeck={() => setView('deck')}
            onOpenMailbox={() => setShowMailbox(true)}
            onOpenFirstAid={() => setShowFirstAid(true)}
            isPlaying={isPlaying} toggleSound={toggleSound}
            hasUnreadMail={hasUnreadMail}
            energy={energy} setEnergy={handleEnergySelect}
            todoList={todoList} toggleTimer={toggleTimer} completeTask={completeTask}
          />
        )}

        {view === 'deck' && <DeckView onBack={() => setView('main')} />}

        <Mailbox
          isOpen={showMailbox} onClose={() => setShowMailbox(false)}
          letters={letters} selectedLetter={null} onSelectLetter={() => { }}
          onOpenWrite={() => { }} hasUnread={hasUnreadMail}
        />

        <FirstAid
          isOpen={showFirstAid} onClose={() => setShowFirstAid(false)}
          userName={userName} beanName={beanName}
        />

      </div>
    </div>
  );
}