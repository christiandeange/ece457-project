function [ globalBestFitness globalBestSolution fitnesses solutions ] = TabuSearch( schedule, rooms, tabuListLength, students, maxIterations, handle )
% TabuSearch Algorithm to find best schedule
%
%       schedule Schedule
%          rooms List(Classroom)
% tabuListLength Number
%       students List(Student)
%  maxIterations Number
%         handle Object Handles
%
% Returns the best fitness and solutions for the inputs

bestSolution = schedule;
bestFitness = Inf;
globalBestSolution = bestSolution;
globalBestFitness = bestFitness;

tabuList = zeros(length(schedule.courseMappings));

for iterations = 1:maxIterations,
    
    % Find best neighbour of current schedule and move to it
    % Aspiration allows a solution better than global best to be taken,
    % even if the solution is currently tabu'ed
    
    [ bestSolution bestFitness tabuList ] = ...
        getBestNeighbourForSchedule( bestSolution, globalBestFitness, rooms, tabuList, tabuListLength, students );
    
    fitnesses(iterations) = bestFitness; %#ok
    solutions(iterations) = bestSolution; %#ok
    
    % Update global best fitness & solution
    if bestFitness < globalBestFitness,
        globalBestFitness = bestFitness;
        globalBestSolution = bestSolution;
    end
    
    % Update the UI with the global best fitness after this iteration
    set(handle.Cur_Iter_val,'String', int2str(iterations));
    set(handle.Cur_Best_val,'String', int2str(globalBestFitness));
    drawnow;
    
    if fitnesses(iterations) == 0,
        break
    end
end

end


function [ bestNeighbourSolution bestNeighbourFitness tabuList ] = getBestNeighbourForSchedule( schedule, aspirationFitness, rooms, tabuList, tabuListLength, students )

bestNeighbourSolution = schedule;
bestNeighbourFitness = Inf;
bestNeighbourIndex = 0;
bestNeighbourSwapIndex = 0;

% Find the best neighbour of each course and return the best
for k = 1:length(schedule.courseMappings)
    [neighbourSched fitness secondCourseTabu] = getBestNeighbour(schedule, aspirationFitness, k, rooms, tabuList, students);
    
    if fitness <= bestNeighbourFitness,
        bestNeighbourSolution = neighbourSched;
        bestNeighbourFitness = fitness;
        bestNeighbourIndex = k;
        bestNeighbourSwapIndex = secondCourseTabu;
    end
    
end

if isinf(bestNeighbourFitness),
    % It's possible that all feasible moves are tabu'ed
    bestNeighbourFitness = GetFitness(bestNeighbourSolution, students);
end

% Evaporate tabu list
tabuList = tabuList - 1;
tabuList(tabuList < 0) = 0;

% Add new course(s), if necessary, to tabu list
if bestNeighbourIndex ~= 0,
    tabuList(bestNeighbourIndex) = tabuListLength;
    if bestNeighbourSwapIndex ~= 0
        tabuList(bestNeighbourSwapIndex) = tabuListLength;
    end
end

end


function [bestNeighbourSched bestNeighbourFitness secondCourseTabu] = getBestNeighbour(schedule, aspirationFitness, currentCourse, rooms, tabuList, students)
currentBestNeighbour = schedule;
currentBestNeighbourFitness = Inf;
secondCourseTabu = 0;
coursemappings = schedule.courseMappings;
currentCoursemapping = coursemappings(currentCourse);
course = currentCoursemapping.course;
duration = course.duration;
days = schedule.days;
timeslots = schedule.timeslots;

% Find best of moving day/time
for i = 1:days,
    for j = 1:(timeslots - duration + 1),
        if (i ~= currentCoursemapping.day) || (j ~= currentCoursemapping.timeSlot),
            newNeighbourMapping = CourseMapping(course, currentCoursemapping.room, i, j);
            newNeighbourMappings = coursemappings;
            newNeighbourMappings(currentCourse) = newNeighbourMapping;
            newNeighbourSched = Schedule(newNeighbourMappings, days, timeslots);
            fitness = GetFitness(newNeighbourSched, students);
            
            % Allow non-tabu'ed better solutions, or tabu'ed solutions
            % better than the global best
            if (tabuList(course.courseID) == 0 && fitness < currentBestNeighbourFitness) || ...
                    (tabuList(course.courseID) ~= 0 && fitness < aspirationFitness),
                secondCourseTabu = 0;
                currentBestNeighbour = newNeighbourSched;
                currentBestNeighbourFitness = fitness;
            end
        end
    end
end

% Find best of swapping room
for i = 1:length(rooms),
    if currentCoursemapping.room.roomID ~= rooms(i).roomID,
        newNeighbourMapping = CourseMapping(course, rooms(i), currentCoursemapping.day, currentCoursemapping.timeSlot);
        newNeighbourMappings = coursemappings;
        newNeighbourMappings(currentCourse) = newNeighbourMapping;
        newNeighbourSched = Schedule(newNeighbourMappings, days, timeslots);
        fitness = GetFitness(newNeighbourSched, students);
        
        % Allow non-tabu'ed better solutions, or tabu'ed solutions
        % better than the global best
        if (tabuList(course.courseID) == 0 && fitness < currentBestNeighbourFitness) || ...
                (tabuList(course.courseID) ~= 0 && fitness < aspirationFitness),
            secondCourseTabu = 0;
            currentBestNeighbour = newNeighbourSched;
            currentBestNeighbourFitness = fitness;
        end
    end
end

% Find best of swapping with other class
for i = 1:length(coursemappings),
    if coursemappings(i).course.courseID ~= course.courseID,
        
        newEndSlot1 = currentCoursemapping.timeSlot + coursemappings(i).course.duration;
        newEndSlot2 = coursemappings(i).timeSlot + currentCoursemapping.course.duration;
        
        % Make sure that swapping courses won't lead to one ending after
        % the maximum number of timeslots available
        if newEndSlot1 <= schedule.timeslots && newEndSlot2 <= schedule.timeslots,
            newNeighbourMapping1 = CourseMapping(course, coursemappings(i).room, coursemappings(i).day, coursemappings(i).timeSlot);
            newNeighbourMapping2 = CourseMapping(coursemappings(i).course, currentCoursemapping.room, currentCoursemapping.day, currentCoursemapping.timeSlot);
            newNeighbourMappings = coursemappings;
            newNeighbourMappings(currentCourse) = newNeighbourMapping1;
            newNeighbourMappings(i) = newNeighbourMapping2;
            newNeighbourSched = Schedule(newNeighbourMappings, days, timeslots);
            fitness = GetFitness(newNeighbourSched, students);
            
            % Allow non-tabu'ed better solutions, or tabu'ed solutions
            % better than the global best
            if (tabuList(course.courseID) == 0 && tabuList(i) == 0 && fitness < currentBestNeighbourFitness) || ...
                    ((tabuList(course.courseID) ~= 0 || tabuList(i) ~= 0) && fitness < aspirationFitness),
                secondCourseTabu = coursemappings(i).course.courseID;
                currentBestNeighbour = newNeighbourSched;
                currentBestNeighbourFitness = fitness;
            end
        end
        
    end
end

% Set returns
bestNeighbourSched = currentBestNeighbour;
bestNeighbourFitness = currentBestNeighbourFitness;

end
