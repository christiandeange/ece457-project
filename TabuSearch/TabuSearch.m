function [ globalBestFitness, globalBestSolution ] = TabuSearch( schedule, rooms, tabuListLength, students, maxIterations )
    
    bestSolution = schedule;
    bestFitness = Inf;
    globalBestSolution = bestSolution;
    globalBestFitness = bestFitness;
    
    tabuList = zeros(length(schedule.courseMappings));
    
    iterations = 1;
    while iterations <= maxIterations,

        [ bestSolution bestFitness tabuList ] = ...
            getBestNeighbourForSchedule( bestSolution, rooms, tabuList, tabuListLength, students );

        if bestFitness < globalBestFitness,
            globalBestFitness = bestFitness;
            globalBestSolution = bestSolution;
            fprintf('iterations = %d, global best fitness = %d\n', iterations, globalBestFitness);
        end
        
        iterations = iterations + 1;
    end
    
end


function [ bestNeighbourSolution bestNeighbourFitness tabuList ] = getBestNeighbourForSchedule( schedule, rooms, tabuList, tabuListLength, students )

    bestNeighbourSolution = schedule;
    bestNeighbourFitness = Inf;
    bestNeighbourIndex = 0;
    bestNeighbourSwapIndex = 0;

    for k = 1:length(schedule.courseMappings)
        [neighbourSched fitness secondCourseTabu] = getBestNeighbour(schedule, k, rooms, tabuList, students);

        if fitness < bestNeighbourFitness,
            bestNeighbourSolution = neighbourSched;
            bestNeighbourFitness = fitness;
            bestNeighbourIndex = k;
            bestNeighbourSwapIndex = secondCourseTabu;
        end

    end

    tabuList = tabuList - 1;
    tabuList(tabuList < 0) = 0;

    if bestNeighbourIndex ~= 0,
        tabuList(bestNeighbourIndex) = tabuListLength;
        if bestNeighbourSwapIndex ~= 0
           tabuList(bestNeighbourSwapIndex) = tabuListLength;
        end
    end

end


function [bestNeighbourSched bestNeighbourFitness secondCourseTabu] = getBestNeighbour(schedule, currentCourse, rooms, tabuList, students)
    currentBestNeighbour = schedule;
    currentBestNeighbourFitness = Inf;
    secondCourseTabu = 0;
    coursemappings = schedule.courseMappings;
    currentCoursemapping = coursemappings(currentCourse);
    course = currentCoursemapping.course;
    duration = course.duration;
    days = schedule.days;
    timeslots = schedule.timeslots;
    
    if tabuList(course.courseID) == 0   
        %find best of moving
        for i = 1:days
            for j = 1 : timeslots - duration + 1
                if (i ~= currentCoursemapping.day || j ~= currentCoursemapping.timeSlot)
                    newNeighbourMapping = CourseMapping(course, currentCoursemapping.room, i, j);
                    newNeighourMappings = coursemappings;
                    newNeighourMappings(currentCourse) = newNeighbourMapping;
                    newNeighbourSched = Schedule(newNeighourMappings, days, timeslots);
                    fitness = GetFitness(newNeighbourSched, students);
                    if fitness < currentBestNeighbourFitness
                        secondCourseTabu = 0;
                        currentBestNeighbour = newNeighbourSched;
                        currentBestNeighbourFitness = fitness;
                    end
                end
            end
        end
        
        %find best of swapping room
        for i = 1:length(rooms)
            if (currentCoursemapping.room.roomID ~= rooms(i).roomID)
                newNeighbourMapping = CourseMapping(course, rooms(i), currentCoursemapping.day, currentCoursemapping.timeSlot);
                newNeighourMappings = coursemappings;
                newNeighourMappings(currentCourse) = newNeighbourMapping;
                newNeighbourSched = Schedule(newNeighourMappings, days, timeslots);
                fitness = GetFitness(newNeighbourSched, students);
                if fitness < currentBestNeighbourFitness
                    secondCourseTabu = 0;
                    currentBestNeighbour = newNeighbourSched;
                    currentBestNeighbourFitness = fitness;
                end
            end
        end
        
        %find best of swapping with other class
        for i = 1:length(coursemappings)
            if coursemappings(i).course.courseID ~= course.courseID
                
                newEndSlot1 = currentCoursemapping.timeSlot + coursemappings(i).course.duration;
                newEndSlot2 = coursemappings(i).timeSlot + currentCoursemapping.course.duration;
                
                if newEndSlot1 <= schedule.timeslots && newEndSlot2 <= schedule.timeslots,
                    if tabuList(i) == 0
                        newNeighbourMapping1 = CourseMapping(course, coursemappings(i).room, coursemappings(i).day, coursemappings(i).timeSlot);
                        newNeighbourMapping2 = CourseMapping(coursemappings(i).course, currentCoursemapping.room, currentCoursemapping.day, currentCoursemapping.timeSlot);
                        newNeighourMappings = coursemappings;
                        newNeighourMappings(currentCourse) = newNeighbourMapping1;
                        newNeighourMappings(i) = newNeighbourMapping2;
                        newNeighbourSched = Schedule(newNeighourMappings, days, timeslots);
                        fitness = GetFitness(newNeighbourSched, students);
                        if fitness < currentBestNeighbourFitness
                            secondCourseTabu = coursemappings(i).course.courseID;
                            currentBestNeighbour = newNeighbourSched;
                            currentBestNeighbourFitness = fitness;
                        end
                    end
                end
            
            end
        end
    
    end

    % set return
    bestNeighbourSched = currentBestNeighbour;
    bestNeighbourFitness = currentBestNeighbourFitness;
    
end