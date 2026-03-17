import React, { useState, useEffect } from "react";
import { Trash2, ArrowUp, ArrowDown, Pencil, Plus, Save, X } from "lucide-react";
import useDebounce from "./hooks/useDebounce";
import PomodoroTimer from "./pomodoro.jsx";
import "./ToDoList.css";
import { Link, useNavigate } from 'react-router-dom';
import { API_URL, getAuthHeaders } from "./services/api";

function ToDoList() {
  const Navigate = useNavigate();
  const [tasks, setTasks] = useState([]);
  const [newTask, setNewTask] = useState("");
  const [editingIndex, setEditingIndex] = useState(null);
  const [editingText, setEditingText] = useState("");
  const [searchQuery, setSearchQuery] = useState("");
  useEffect(() => {
    if (!localStorage.getItem('token')) {
      Navigate('/login');
    }
  
    fetchTasks();
  }, []);

  function handleInputChange(event) {
    setNewTask(event.target.value);
  }

  const debouncedSearchQuery = useDebounce(searchQuery, 300);

  async function fetchTasks() {
    try {
      
      const url = debouncedSearchQuery
        ? `${API_URL}/tasks?query=${encodeURIComponent(debouncedSearchQuery)}`
        : `${API_URL}/tasks`;
      const response = await fetch(url, {
        headers: getAuthHeaders()
      });
      const data = await response.json();
      setTasks(data);
    } catch (error) {
      console.error("Error fetching tasks:", error);
    }
  }

  useEffect(() => {
    fetchTasks();
  }, [debouncedSearchQuery]);

  async function addTask() {
    if (newTask.trim() !== "") {
      try {
        const response = await fetch(`${API_URL}/tasks`, {
          method: "POST",
          headers: { "Content-Type": "application/json", ...getAuthHeaders() },
          body: JSON.stringify({ text: newTask })
        });
        const task = await response.json();
        setTasks([...tasks, task]);
        setNewTask("");
      } catch (error) {
        console.error("Error adding task:", error);
      }
    }
  }

  async function deleteTask(id) {
    try {
      await fetch(`${API_URL}/tasks/${id}`, {
        method: "DELETE",
        headers: getAuthHeaders(),
      });
      setTasks(tasks.filter(t => t.id !== id));
    } catch (error) {
      console.error("Error deleting task:", error);
    }
  }

  async function saveEdit(index) {
    const task = tasks[index];
    try {
      await fetch(`${API_URL}/tasks/${task.id}`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json", ...getAuthHeaders() },
        body: JSON.stringify({ text: editingText, completed: task.completed })
      });
      const updatedTasks = [...tasks];
      updatedTasks[index].text = editingText;
      setTasks(updatedTasks);
      setEditingIndex(null);
    } catch (error) {
      console.error("Error updating task:", error);
    }
  }

  async function toggleCompleted(index) {
    const task = tasks[index];
    try {
      await fetch(`${API_URL}/tasks/${task.id}`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json", ...getAuthHeaders() },
        body: JSON.stringify({ text: task.text, completed: !task.completed })
      });
      const updatedTasks = [...tasks];
      updatedTasks[index].completed = !updatedTasks[index].completed;
      setTasks(updatedTasks);
    } catch (error) {
      console.error("Error toggling task:", error);
    }
  }

  function moveTaskUp(index) {
    if (index > 0) {
      const updatedTasks = [...tasks];
      [updatedTasks[index], updatedTasks[index - 1]] = [
        updatedTasks[index - 1],
        updatedTasks[index],
      ];
      setTasks(updatedTasks);
    }
  }

  function moveTaskDown(index) {
    if (index < tasks.length - 1) {
      const updatedTasks = [...tasks];
      [updatedTasks[index], updatedTasks[index + 1]] = [
        updatedTasks[index + 1],
        updatedTasks[index],
      ];
      setTasks(updatedTasks);
    }
  }

  function startEditing(index) {
    setEditingIndex(index);
    setEditingText(tasks[index].text);
  }

  const completedCount = tasks.filter((t) => t.completed).length;

  return (
    <div className="app-container">
      <div className="to-do-list">
        <h1>To Do List</h1>

        <div>
          <input 
            className="search" 
            placeholder="Search" 
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />
          <input
            onKeyDown={(e) => e.key === "Enter" && addTask()}
            type="text"
            placeholder="Enter a task..."
            value={newTask}
            onChange={handleInputChange}
          />
          <button className="add-button" onClick={addTask}>
            <Plus size={20} />
          </button>
        </div>

        <div className="progress-container">
          <div className="progress-top">
            <span>Progress</span>
            <span>{completedCount} / {tasks.length}</span>
          </div>

          <div className="progress-bar">
            <div
              className="progress-fill"
              style={{
                width: tasks.length === 0 ? "0%" : `${(completedCount / tasks.length) * 100}%`,
              }}
            ></div>
          </div>
        </div>

        <ol>
          {tasks.map((task, index) => (
            <li key={task.id}>
              {editingIndex === index ? (
                <>
                  <input
                    className="edit-input"
                    value={editingText}
                    onChange={(e) => setEditingText(e.target.value)}
                    onKeyDown={(e) => e.key === "Enter" && saveEdit(index)}
                  />

                  <button className="add-button" onClick={() => saveEdit(index)}>
                    <Save size={20} />
                  </button>

                  <button
                    className="delete-button"
                    onClick={() => setEditingIndex(null)}
                  >
                    <X size={20} />
                  </button>
                </>
              ) : (
                <>
                  <input
                    type="checkbox"
                    checked={task.completed}
                    onChange={() => toggleCompleted(index)}
                  />

                  <span className={task.completed ? "completed text" : "text"}>
                    {task.text}
                  </span>

                  <button className="move-button" onClick={() => startEditing(index)}>
                    <Pencil size={20} />
                  </button>

                  <button className="delete-button" onClick={() => deleteTask(task.id)}>
                    <Trash2 size={20} />
                  </button>

                  <button className="move-button" onClick={() => moveTaskUp(index)}>
                    <ArrowUp size={20} />
                  </button>

                  <button className="move-button" onClick={() => moveTaskDown(index)}>
                    <ArrowDown size={20} />
                  </button>
                </>
              )}
            </li>
          ))}
        </ol>
      </div>

      <PomodoroTimer />
    </div>
  );
}

export default ToDoList;
